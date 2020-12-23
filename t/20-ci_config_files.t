use warnings;
use strict;
use Test::More;

use Data::Dumper;
use STEVEB::Dist::Mgr::FileData;

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my @github_ci_config = _github_ci();

print "$_\n" for @github_ci_config;

done_testing;

