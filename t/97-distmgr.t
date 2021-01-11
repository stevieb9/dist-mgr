use warnings;
use strict;

use Capture::Tiny qw(:all);
use Cwd qw(getcwd);
use Data::Dumper;
use File::Copy;
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

system("rm", "-rf", $repo_dir);

my $cwd = getcwd();

my %cpan_args = (
    dry_run     => 1,
);

# create
{
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
    my $output = `$cmd`;
    print $output;

    my $tpl_dir = "$cwd/t/data/distmgr/create_test-module";
    copy_second_module($tpl_dir);

    compare_files($tpl_dir, 'create');

    after();
}

# dist
{
    my $tpl_dir = 't/data/dist_test-module';

    before ();

    my @dist_cmd_list = (
        'distmgr',
        'dist',
        '-m Test::Module',
        '-a "Steve Bertrand"',
        '-e steveb@cpan.org',
    );

    my $cmd = join ' ', @dist_cmd_list;

#    my $output = `$cmd`;
#    print $output;

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

    mkdir "$repo_dir/lib/Test/Module" or die "Can't create 'lib/Module' dir in $repo_dir\n";
    copy
        "$src/lib/Test/Module/Second.pm",
        "$repo_dir/lib/Test/Module/Second.pm"
    or die "Can't copy Second.pm: $!";

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
sub compare_files {
    if (@_ != 2) {
        die "compare_files() needs \$tpl dir, and 'phase' sent in\n";
    }

    my ($tpl, $phase) = @_;

    like getcwd(), qr/$repos_dir$/, "in $repos_dir directory ok";
    die "Not in $repos_dir!" if getcwd() !~ /$repos_dir$/;

    chdir $repo_dir or die "Can't go into $repo_dir: $!\n";
    like getcwd(), qr/$repo_dir$/, "in $repo_dir directory ok";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($tpl);
    my $file_count = 0;

    if (1) {
        my @files;
        for my $tf (@template_files) {
            (my $nf = $tf) =~ s/$tpl\///;
            # nf == new file
            # tf == template file
            if (-f $nf) {
                next if $nf =~ m|^\.git/|;

                push @files, $nf;
                open my $tfh, '<', $tf or die $!;
                open my $nfh, '<', $nf or die $!;

                my @tf = <$tfh>;
                my @nf = <$nfh>;

                close $tfh;
                close $nfh;

                for (0 .. $#tf) {
                    if ($nf eq 'Changes') {
                        if ($_ == 2) {
                            if ($phase =~ /^create$/) {
                                # UNREL/Date line
                                like $nf[$_], qr/UNREL/, "Changes line 2 phase '$phase' contains UNREL ok";
                                next;
                            }
                        }
                        if ($nf[$_] =~ /^\s{4}-\s+$/) {
                            like $nf[$_], qr/^\s{4}-\s+$/, "line with only a dash ok";
                            next;
                        }
                    }
                    # Module version may differ due to processing
                    if ($nf =~ m|lib/Test/.*\.pm|) {
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
        is scalar $file_count, $base_count, "file count matches number of files in module template";
    }
    else {
        warn "SKIPPING $phase FILE COMPARE CHECKS!";
    }

    chdir $cwd or die "Can't go into $cwd: $!\n";
    like getcwd(), qr/$cwd$/, "in $cwd directory ok";
}
