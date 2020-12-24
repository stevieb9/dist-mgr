use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Hook::Output::Tiny;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my $mods = [qw(Test::Module)];
my $cwd = getcwd();

my %module_args = (
    author  => 'Test Author',
    email   => 'test@example.com',
    modules => $mods,
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

remove_init();

# full run
{
    # Initialize

    before();

    # Create the new dsitribution

    $h->hook('stderr');
    init(%module_args);
    $h->unhook('stderr');

    # Verify STDOUT from Module::Starter

    my @stderr = $h->stderr;
    is scalar @stderr, 11, "Module::Starter has proper print output";

    #TODO: write function that copies the contents of the new dist into the
    # repo dir

    # Change into the new distribution's root directory

    check_and_change_into_module_dir();

    # Cleanup

    after();
}

remove_init();

done_testing;

sub before {
    like $cwd, qr/steveb-dist-mgr/, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    if (! -d 'init') {
        mkdir 'init' or die $!;
    }

    is -d 'init', 1, "'init' dir created ok`";

    chdir 'init' or die $!;
    like getcwd(), qr/$work\/init$/, "in $work/init directory ok";
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/steveb-dist-mgr/, "back in root directory ok";
}
sub check_and_change_into_module_dir {
    is -d 'Test-Module', 1, "Test-Module directory created ok";

    chdir 'Test-Module' or die $!;
    like getcwd(), qr/Test-Module/, "in Test-Module dir ok";
}

