use warnings;
use strict;

use Cwd qw(getcwd);
use Test::More;
use Hook::Output::Tiny;
use Dist::Mgr qw(:private);

use lib 't/lib';
use Helper qw(:all);

# Regression coverage for module names of varying namespace depth. The
# lib/ tree grows a directory level per component (eg. Foo::Bar::Baz =>
# lib/Foo/Bar/Baz.pm), so move_distribution_files() must validate the
# move for any depth, not just the two-component default. This test does
# NOT mock _default_distribution_file_count() (unlike 50-*), so it
# exercises the real depth-aware count.

my $cwd = getcwd();
my $in_cwd = getcwd() =~ _dist_dir_re();
is $in_cwd, 1, "in repo root dir ok";

my $init_dir = 't/data/work/init';

# module name => the lib/ path its .pm file should land at
my %modules = (
    'Single'              => 'lib/Single.pm',
    'Two::Part'           => 'lib/Two/Part.pm',
    'Three::Part::Name'   => 'lib/Three/Part/Name.pm',
    'Four::Part::Deep::Ns' => 'lib/Four/Part/Deep/Ns.pm',
);

for my $module (sort keys %modules) {
    my $pm_path = $modules{$module};

    remove_init();
    mkdir $init_dir or die $! if ! -e $init_dir;
    chdir $init_dir or die $!;

    my $h = Hook::Output::Tiny->new;
    $h->hook('stderr');
    init(
        author  => 'Steve Bertrand',
        email   => 'steveb@cpan.org',
        modules => [$module],
        license => 'artistic2',
        builder => 'ExtUtils::MakeMaker',
    );
    $h->unhook('stderr');

    my $dist_dir = $module;
    $dist_dir =~ s/::/-/g;

    # move_distribution_files() croaks on a count mismatch; success is a
    # clean return of 0 with the files relocated up out of $dist_dir.
    my $rv;
    my $ok = eval { $rv = move_distribution_files($module); 1 };

    is $ok, 1, "move_distribution_files() ok for '$module' (depth-aware)";
    is $rv, 0, "...returned 0 for '$module'";
    is -f $pm_path, 1, "...module file landed at $pm_path";
    is -e $dist_dir, undef, "...source '$dist_dir' dir removed";

    chdir $cwd or die $!;
}

is getcwd() =~ _dist_dir_re(), 1, "back in repo root dir";
remove_init();

done_testing;
