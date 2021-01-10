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

my $repos_dir = $ENV{DIST_MGR_REPO_DIR};
my $repo = 'test-module';
my $repo_dir = "$repos_dir/$repo";
my $tpl_dir;

my $cwd = getcwd();

my %cpan_args = (
    dry_run     => 1,
);

# create
{
    $tpl_dir = 't/data/create_test-module';

    before ();

    my @create_cmd_list = (
        'distmgr',
        'create',
        '--destroy',
        '-m Test::Module',
        '-a "Steve Bertrand"',
        '-e steveb@cpan.org',
        '-r test-module',
        '-u stevieb9',
    );

    my $cmd = join ' ', @create_cmd_list;

    print "$cmd\n";

    after();
}

# dist
{
    $tpl_dir = 't/data/dist_test-module';

    before ();

    my @dist_cmd_list = (
        'distmgr',
        'dist',
        '-m Test::Module',
        '-a "Steve Bertrand"',
        '-e steveb@cpan.org',
    );

    my $cmd = join ' ', @dist_cmd_list;

    print "$cmd\n";

    after();
}

done_testing;
#system("rm", "-rf", $repo_dir);

sub before {
    chdir $repos_dir or die "Can't chdir to $repos_dir";
    like getcwd(), qr/$repos_dir$/, "in $repos_dir directory ok";
    die "Not in $repos_dir!" if getcwd() !~ /$repos_dir$/;
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/dist-mgr/, "back in root directory $cwd ok";
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
sub copy_second_module {
    my ($src) = @_;

    mkdir "$repo_dir/lib/Module" or die "Can't create 'Module' dir in $repo_dir\n";
    copy
        "$src/lib/Test/Module/Second.pm",
        "$repo_dir/lib/Test/Module/Second.pm"
    or die "Can't copy Second.pm";

    is -e "$repo_dir/lib/Test/Module/Second.pm", 1, "Second.pm copied ok to $repo_dir/lib/Test/Module";

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
sub remove_tarball {
    my @dist_files = glob('*Acme-STEVEB*');
    for (@dist_files) {
        unlink $_ or die "can't unlink dist file $_: $!";
        is -e $_, undef, "dist file $_ removed ok";
    }
}
sub post_release_file_count {
    is getcwd(), $$repo_dir, "in the repo dir ok";

    my $template_dir = "$cwd/t/data/template/release_module_template/";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    my $file_count = 0;

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
        is scalar $file_count, $base_count, "file count matches number of files in module_template";
    }
    else {
        warn "SKIPPING POST RELEASE FILE COMPARE CHECKS!";
    }
}
sub post_prep_next_cycle_file_count {
    is getcwd(), $repo_dir, "in the repo dir ok";

    my $template_dir = "$cwd/t/data/template/release_module_template/";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    my $tpl_count = 0;
    my $new_count = 0;

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
                    is $nf[$_], $tf[$_], "$nf file line $_ matches the template $tf ok";
                }
                $tpl_count++;
            }
            $new_count++;
        }
        my $base_count = scalar @template_files;
        is scalar $new_count, $base_count, "file count matches number of files in module_release_template";
    }
    else {
        warn "SKIPPING FILE NEXT CYCLE COMPARE CHECKS!";
    }
}
