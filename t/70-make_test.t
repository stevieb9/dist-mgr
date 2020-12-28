use warnings;
use strict;

use Hook::Output::Tiny;
use Mock::Sub;
use Test::More;
use version;

my ($m, $sub_system);

BEGIN {

    # Too low a version on Windows
    {
        my $win_ver_ok = version->parse('5.12.0') < version->parse($^V);

        if ($^O =~ /win32/i && ! $win_ver_ok) {
            plan skip_all => "Windows must have minimum perl version 5.12 for these tests"
        }
    }

    $m = Mock::Sub->new;
    my $h = Hook::Output::Tiny->new;

    $h->hook('stderr');
    $sub_system = $m->mock(
        'system',
        return_value => 'success'
    );
    $h->unhook('stderr');

    my @stderr = $h->stderr;

    like $stderr[0], qr/WARNING!.* global core/, "warned about mocking core sub ok";
};

use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);

my $cwd = getcwd();
like $cwd, qr/dist-mgr$/, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr$/;

my $exit_code = make_test();

is $sub_system->called, 1, "system() was called ok";
is $exit_code, 'success', "...and return is ok";

done_testing;
