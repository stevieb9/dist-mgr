use warnings;
use strict;
use Test::More;

use Data::Dumper;
use STEVEB::Dist::Mgr::FileData;

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my @travis_ci_config = _travis_ci();

open my $fh, '>', "$orig/.travis.yml" or die $!;

for (@travis_ci_config) {
    print $fh "$_\n";
}

done_testing;

