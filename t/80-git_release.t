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

# git_release
{
    is eval { git_release(); 1 }, undef, "git_release() requires a version ok";
    like $@, qr/requires a version/, "...and error is sane";

    git_release(0.01);
}

chdir $cwd or die $!;
like getcwd(), qr/dist-mgr$/, "back in root dir ok";

remove_init();

done_testing;
