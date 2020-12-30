use warnings;
use strict;

use Capture::Tiny qw(:all);
use Cwd qw(getcwd);
use Data::Dumper;
use File::Find::Rule;
use File::Find;
use Test::More;
use Dist::Mgr qw(:all);
use version;

BEGIN {
    # DIST_MGR_REPO_DIR eg. /home/spek/repos

    if (!$ENV{DIST_MGR_GIT_TEST} || !$ENV{DIST_MGR_REPO_DIR}) {
        plan skip_all => "DIST_MGR_GIT_TEST and DIST_MGR_REPO_DIR env vars must be set";
    }
}

use lib 't/lib';
use Helper qw(:all);

my $work = $ENV{DIST_MGR_REPO_DIR};

my $mods = [qw(Acme::STEVEB)];
my $cwd = getcwd();

my %cpan_args = (
    dry_run     => 1,
);

{
    before ();

    my $new_ver = update_version();

    # changes()

    changes($mods->[0]);
    check_file('Changes', qr/Acme-STEVEB/, "our custom Changes is in place ok");

    # changes_date()

    changes_date('Changes');
    check_file('Changes', qr/\d{4}-\d{2}-\d{2}/, "changes_date() ok");

    changes_bump($new_ver, 'Changes');
    check_file('Changes', qr/UNREL/, "changes_bump() ok");

    changes_date('Changes');
    check_file('Changes', qr/\d{4}-\d{2}-\d{2}/, "changes_date() ok");

    # make_test()

    make_test();

    # git_add

    git_add();

    # git_tag

    git_tag($new_ver);

    # git_release

    git_release($new_ver, 0); # 0 == don't wait for CI tests to run

    # make_dist

    make_dist();

    # Compare all files against the saved template (post release)

    is getcwd(), "$work/acme-steveb", "in the repo dir ok";

    my $template_dir = "$cwd/t/data/release_module_template/";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    my $file_count = 1; #FIXME: Change back to 0 after we clean up the dist tarball

    if (1) {
        for my $tf (@template_files) {
            (my $nf = $tf) =~ s/$template_dir//;
            # nf == new file
            # tf == template file

            if (-f $nf) {
                open my $tfh, '<', $tf or die $!;
                open my $nfh, '<', $nf or die $!;

                my @tf = <$tfh>;
                my @nf = <$nfh>;

                close $tfh;
                close $nfh;

                for (0 .. $#tf) {
                    if ($nf eq 'Changes') {
                        if ($_ == 2) {
                            # UNREL/Date line
                            like $nf[$_], qr/\d{4}-\d{2}-\d{2}/, "Changes line 2 contains date ok";
                            is $nf[$_] !~ /UNREL/, 1, "Changes line 2 has temp UNREL removed ok";
                            next;
                        }
                        if ($nf[$_] =~ /^\s{4}-\s+$/) {
                            like $nf[$_], qr/^\s{4}-\s+$/, "line with only a dash ok";
                            next;
                        }
                    }
                    if ($nf eq 'lib/Acme/STEVEB.pm') {
                        if ($nf[$_] =~ /\$VERSION/) {
                            # VERSION
                            like $nf[$_], qr/\$VERSION = '\d+\.\d+'/, "Changes line 2 contains date ok";
                            next;
                        }
                    }
                    is $nf[$_], $tf[$_], "$nf file matches the template $tf ok";
                }
                $file_count++;
            }
        }
        my $base_count = scalar @template_files;
        $base_count++; # dist tarball
        is scalar $file_count, $base_count, "file count matches number of files in template, plus the dist tarball";
    }
    else {
        warn "SKIPPING POST RELEASE FILE COMPARE CHECKS!";
    }

    my $dist_file = (glob('*Acme-STEVEB*'))[-1];

    my $output = capture_merged {
        cpan_upload($dist_file, %cpan_args);
    };

    like $output, qr/cowardly refusing/, "cpan_upload() ran ok in dry mode";

    # cleanup

    my @dist_files = glob('*Acme-STEVEB*');
    for (@dist_files) {
        unlink $_ or die "can't unlink dist file $_: $!";
        is -e $_, undef, "dist file $_ removed ok";
    }

    # next release prep

    my $post_release_ver = update_version();

    # next release Changes

    changes_bump($post_release_ver, 'Changes');
    check_file('Changes', qr/UNREL/, "changes_bump() ok");

    # next release lib

    check_file('lib/Acme/STEVEB.pm', qr/$post_release_ver/, "lib ver bump ok");

    # commit and push

    git_commit($post_release_ver);
    git_push();

    # Compare all files against the saved template (post release)

    is getcwd(), "$work/acme-steveb", "in the repo dir ok";

    $template_dir = "$cwd/t/data/release_module_template/";

    @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    $file_count = 1; #FIXME: Change back to 0 after we clean up the dist tarball

    if (1) {
        for my $tf (@template_files) {
            (my $nf = $tf) =~ s/$template_dir//;
            # nf == new file
            # tf == template file

            if (-f $nf) {
                open my $tfh, '<', $tf or die $!;
                open my $nfh, '<', $nf or die $!;

                my @tf = <$tfh>;
                my @nf = <$nfh>;

                close $tfh;
                close $nfh;

                for (0 .. $#tf) {
                    if ($nf eq 'Changes') {
                        if ($_ == 2) {
                            # UNREL/Date line
                            is $nf[$_] !~ qr/\d{4}-\d{2}-\d{2}/, 1, "Changes line 2 contains date ok";
                            is $nf[$_] =~ /UNREL/, 1, "Changes line 2 has temp UNREL removed ok";
                            next;
                        }
                        if ($nf[$_] =~ /^\s{4}-\s+$/) {
                            like $nf[$_], qr/^\s{4}-\s+$/, "line with only a dash ok";
                            next;
                        }
                    }
                    if ($nf eq 'lib/Acme/STEVEB.pm') {
                        if ($nf[$_] =~ /\$VERSION/) {
                            # VERSION
                            like $nf[$_], qr/\$VERSION = '\d+\.\d+'/, "Changes line 2 contains date ok";
                            next;
                        }
                    }
                    is $nf[$_], $tf[$_], "$nf file matches the template $tf ok";
                }
                $file_count++;
            }
        }
        my $base_count = scalar @template_files;
        $base_count++; # dist tarball
        is scalar $file_count, $base_count, "file count matches number of files in template, plus the dist tarball";
    }
    else {
        warn "SKIPPING FILE NEXT CYCLE COMPARE CHECKS!";
    }

    # done!

    after();
}

done_testing;
#system("rm", "-rf", "/home/spek/repos/acme-steveb");

sub before {
    like $cwd, qr/dist-mgr/, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    # clone our test repo
    {
        if (! -e 'acme-steveb') {
            capture_merged {
                `git clone 'https://stevieb9\@github.com/stevieb9/acme-steveb'`;
            };
            is $?, 0, "git cloned 'acme-steveb' test repo ok";
        }
    }

    is -d 'acme-steveb', 1, "'acme-steveb' cloned created ok`";

    chdir 'acme-steveb' or die $!;
    like getcwd(), qr/$work\/acme-steveb$/, "in $work/acme-steveb directory ok";

    git_pull();
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/dist-mgr/, "back in root directory ok";
}
sub file_count {
    my ($expected_count, $msg) = @_;
    die "need \$msg in file_count()" if ! defined $msg;
    my $fs_entry_count;
    find (sub {$fs_entry_count++;}, '.');
    is $fs_entry_count, $expected_count, "num files: $expected_count,  $msg";
}
sub check_file {
    my ($file, $regex, $msg) = @_;
    open my $fh, '<', $file or die $!;
    my @contents = <$fh>;
    close $fh;
    is grep(/$regex/, @contents) >= 1, 1, $msg;
}
sub done {
    done_testing;
#    system("rm", "-rf", "/home/spek/repos/acme-steveb");
    exit;
}
sub update_version {
    # version_info()

    my ($orig_ver) = values %{(version_info('lib/Acme/STEVEB.pm'))[0]};

    release_version($orig_ver);
    my ($new_ver) = values %{(version_info('lib/Acme/STEVEB.pm'))[0]};
    is(
        version->parse($new_ver) > version->parse($orig_ver),
        1,
        "$new_ver is greater than $orig_ver ok"
    );

    return $new_ver;
}
