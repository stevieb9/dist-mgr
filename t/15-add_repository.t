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

{
    add_repository($mf);
}

done_testing();

