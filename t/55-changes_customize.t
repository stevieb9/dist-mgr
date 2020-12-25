use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);

my $orig = 't/data/orig';
my $work = 't/data/work';

done_testing;

