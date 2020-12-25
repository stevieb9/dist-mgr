use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);

my $orig = 't/data/orig/Changes';
my $work = 't/data/work/Changes';

# from initial creation
{
    copy_changes();

    changes('test');
    unlink_changes();
}
done_testing;

