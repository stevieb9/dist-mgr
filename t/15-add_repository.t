use warnings;
use strict;
use Test::More;

use Data::Dumper;
use STEVEB::Dist::Mgr qw(:all);

use lib '.';
use lib 't/lib';
use Helper qw(:all);

unlink_makefile();
copy_makefile();

my $mf = 't/data/work/Makefile.PL';

# bad params
{
    is eval{add_repository(); 1}, undef, "croak if no params ok";
    like $@, qr/Usage: add_repository/, "...and error is sane";

    is eval{add_repository('stevieb9'); 1}, undef, "croak if only author param ok";
    like $@, qr/Usage: add_repository/, "...and error is sane";
}

# add
{
    add_repository('stevieb9', 'add-repo', $mf);
    add_bugtracker('stevieb9', 'add-repo', $mf);
}

done_testing();

