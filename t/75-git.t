use warnings;
use strict;

use Hook::Output::Tiny;
use Mock::Sub;
use Test::More;
use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr qw(:private);
use File::Touch;
use version;

use lib 't/lib';
use Helper qw(:all);

if (! $ENV{RELEASE_TESTING} && ! $ENV{DEV_TEST}) {
    plan skip_all => "RELEASE_TESTING or DEV_TEST env var not set";
}

my $h = Hook::Output::Tiny->new;

my $init_dir = 't/data/work/init';

my $cwd = getcwd();
like $cwd, qr/dist-mgr$/, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr$/;

mkdir_init();
chdir $init_dir or die "Can't change into 'init' dir: $!";
like getcwd(), qr|$init_dir$|, "in temp dir ok";
croak "not in the 'init' dir!" if getcwd() !~ m|$init_dir$|;

my $git_ok = _validate_git();

# validate git installed, exit if not
{
    if (! $git_ok) {
        done_testing;
        exit;
    }
}

# clone our test repo
{
    if (! -e 'test-push') {
        $h->hook;
        my $e = system('git', 'clone', 'https://stevieb9@github.com/stevieb9/test-push');
        $h->hook;

        is $e, 0, "git cloned 'test-push' test repo ok";
    }
}

# git commit
{
    chdir 'test-push' or die $!;
    like getcwd(), qr|$init_dir/test-push$|, "in test-push repo dir ok";
    croak "not in the 'init' dir!" if getcwd() !~ m|$init_dir/test-push$|;

    open my $fh, '>', 'Dist-Mgr.txt' or die $!;
    my $random = rand() + rand() * rand() * 10;
    print $fh $random;
    close $fh;

    $h->hook;
    my $e = _git_commit('0.01');
    $h->unhook;

    is $e == 256 || $e == 0, 1, "_git_commit() exited with success status ok";
}

# git push
{
    $h->hook;
    my $e = _git_push();
    $h->unhook;

    is $e == 0, 1, "_git_push() exited with success status ok";
}
chdir $cwd or die $!;
like getcwd(), qr/dist-mgr$/, "back in root dir ok";

remove_init();

done_testing;
