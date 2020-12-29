use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use File::Find::Rule;
use File::Find;
use Test::More;
use Hook::Output::Tiny;
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

my $version = '0.02';

my $mods = [qw(Acme::STEVEB)];
my $cwd = getcwd();

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => $mods,
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

# generate a distribution, and compare all files against our saved
# distribution template
{
    before();

    # init()

    $h->hook('stderr');
    init(%module_args);
    $h->unhook('stderr');

    my @stderr = $h->stderr;
    is scalar @stderr, 11, "Module::Starter has proper print output";
    is -d 'Acme-STEVEB', 1, "Acme-STEVEB directory created ok";

    # move_distribution_files()

    my $r = move_distribution_files($mods->[0]);
    is $r, 0, "proper return from move_distribution_files()";
    is -e 'Acme-STEVEB', undef, "distribution dir was removed ok";
    like getcwd(), qr/acme-steveb$/, "we're in the repo dir ok";
#    file_count(98, "after move_distribution_files()"); # because .git dir

    # remove_unwanted_files()

    remove_unwanted_files();
#    file_count(94, "after remove_unwanted_files()");
    check_file('lib/Acme/STEVEB.pm', qr/Steve Bertrand/, "our custom module template is in place ok");

    # manifest_skip()

    manifest_skip();
#    file_count(36, "after manifest_skip()");
    is -e 'MANIFEST.SKIP', 1, "MANIFEST.SKIP created ok";
    check_file('MANIFEST.SKIP', qr/BB-Pass/, "it's our custom MANIFEST.SKIP ok");

    # ci_github()

    ci_github();
#    file_count(39, "after ci_github()"); # 16 from 13 because we also count the new directories
    is -e '.github/workflows/github_ci_default.yml', 1, "CI config in place ok";
    check_file(
        '.github/workflows/github_ci_default.yml',
        qr/PL2Bat/,
        "our custom CI config file is in place ok"
    );

    # git_ignore()

    git_ignore();
    is -e '.gitignore', 1, ".gitignore in place ok";
    check_file('.gitignore', qr/BB-Pass/, "our custom .gitignore is in place ok");
#    file_count(94, "after git_ignore()");

    # ci_badges()

    ci_badges('stevieb9', 'acme-steveb', 'lib/Acme/STEVEB.pm');
    check_file('lib/Acme/STEVEB.pm', qr/=for html/, "ci_badges() has html for loop ok");
    check_file('lib/Acme/STEVEB.pm', qr/coveralls/, "ci_badges() dropped coveralls ok");
    check_file('lib/Acme/STEVEB.pm', qr/workflows/, "ci_badges() dropped github actions ok");

    # add_bugtracker()

    add_bugtracker('stevieb9', 'acme-steveb');
    check_file('Makefile.PL', qr/META_MERGE/, "bugtrack META_MERGE added ok");
    check_file('Makefile.PL', qr/bugtracker/, "bugtracker added ok");

    # add_repository()

    add_repository('stevieb9', 'acme-steveb');
    check_file('Makefile.PL', qr/META_MERGE/, "repo META_MERGE added ok");
    check_file('Makefile.PL', qr/repository/, "repository added ok");

    # version_info()

    my ($orig_ver) = values %{ (version_info('lib/'))[0] };
    is $orig_ver, '0.01', "original version is 0.01 ok";

    # version_bump()

    version_bump($version, 'lib/Acme/STEVEB.pm');
    my ($new_ver) = values %{ (version_info('lib/'))[0] };
    is $new_ver, $version, "new version is $version ok";
    is(
        version->parse($new_ver) > version->parse($orig_ver),
        1,
        "$new_ver is greater than $orig_ver ok"
    );

    # changes()

    is sha1sum('Changes'), '97624d56464d7254ef5577e4a0c8a098d6c6d9e6', "updated Changes has proper md5 ok";
    changes($mods->[0]);
    check_file('Changes', qr/Acme-STEVEB/, "our custom Changes is in place ok");
    is sha1sum('Changes'), '29bd43ee41fc555186bb2a736c86af8241098f21', "updated Changes has proper md5 ok";

    # changes_date()

    changes_date('Changes');
    check_file('Changes', qr/\d{4}-\d{2}-\d{2}/, "changes_date() ok");

    # make_test()

    make_test();

    # git_add

    git_add();

    # git_tag

    git_tag($version);

    # git_release

    git_release($version, 0); # 0 == don't wait for CI tests to run

    # make_dist

    make_dist();

    ##
    ## upload here
    ##

    # Compare all files against the saved template

    is getcwd(), "$work/acme-steveb", "in the repo dir ok";

    my $template_dir = "$cwd/t/data/module_template/";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    my $file_count = 1; #FIXME: Change back to 0 after we clean up the dist tarball

    if (1) {
        for my $tf (@template_files) {
            (my $nf = $tf) =~ s/$template_dir//;
            # nf == new file
            # tf == template file

            print "TF: $tf\n";
            if (-f $nf) {
                print "NF: $nf\n";
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
                    }
                    if ($nf eq 'lib/Acme/STEVEB.pm') {
                        if ($nf[$_] =~ /\$VERSION/) {
                            # VERSION
                            like $nf[$_], qr/\$VERSION = '0.02'/, "Changes line 2 contains date ok";
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
        warn "SKIPPING FILE COMPARE CHECKS!";
    }

    # Cleanup

    after();
}

done_testing;
system("rm", "-rf", "/home/spek/repos/acme-steveb");

sub before {
    like $cwd, qr/dist-mgr/, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    # clone our test repo
    {
        if (! -e 'acme-steveb') {
            #$h->hook; # Breaks the clone process for some reason
            my $e = system('git', 'clone', 'https://stevieb9@github.com/stevieb9/acme-steveb');
            #$h->hook;

            is $e, 0, "git cloned 'acme-steveb' test repo ok";
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
    system("rm", "-rf", "/home/spek/repos/acme-steveb");
    exit;
}
