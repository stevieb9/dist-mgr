use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

{

    is
        eval { move_distribution_files(); 1 },
        undef,
        "move_distribution_files() needs a module name sent in";
    like $@, qr/requires a module name/, "...and error is sane";

    # Invalid source dir check (Not a directory)

    is
        eval { move_distribution_files('Test/Module'); 1 },
        undef,
        "move_distribution_files() croaks with bad source dir";
    like $@, qr/move files from the/, "...and error is sane";

}

done_testing;

