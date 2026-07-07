use warnings;
use strict;

use Cwd qw(getcwd);
use Dist::Mgr qw(:private);
use File::Temp qw(tempdir);
use Test::More;

# _git_clone() failure reporting. git refuses to clone into a non-empty
# destination locally, exiting 128 before any network I/O, so we can drive
# the failure path deterministically and offline.

if (! _validate_git()) {
    plan skip_all => "git is not installed";
}

my $cwd  = getcwd();
my $tmp  = tempdir(CLEANUP => 1);
my $user = 'nonexistent-user';
my $repo = 'dist-mgr-clone-fail-test';

chdir $tmp or die "Can't chdir to '$tmp': $!";

# Occupy the destination so git bails with its 'already exists' fatal
mkdir $repo or die "Can't create '$repo' dir: $!";
open my $fh, '>', "$repo/placeholder" or die $!;
print $fh "occupied\n";
close $fh or die $!;

my $ok = eval {
    git_clone($user, $repo);
    1;
};
my $err = $@;

chdir $cwd or die "Can't chdir back to '$cwd': $!";

is $ok, undef, "git_clone() croaks when the clone fails ok";

like $err, qr{Git clone of '$user/$repo' failed with exit code: 128},
    "...reports the decoded git exit code, not the raw wait status ok";

like $err, qr{already exists and is not an empty directory},
    "...surfaces git's own error message ok";

unlike $err, qr{DIRECTORY.*ALREADY EXISTS},
    "...drops the fabricated 'ALREADY EXISTS' text ok";

unlike $err, qr{32768},
    "...does not leak the raw 32768 wait status ok";

done_testing;
