use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Module::Bump::Version qw(:all);

my $f = 't/data/orig/One.pm';
my $d = 't/data/orig';

# bad params
{
    # no version
    is eval {
        bump_version();
        1
    }, undef, "no supplied version croaks ok";
    like $@, qr/version parameter/, "...and error is sane";

    # invalid version
    is eval {
        bump_version('aaa');
        1
    }, undef, "invalid version croaks ok";
    like $@, qr/The version number/, "...and error is sane";

    # invalid file system entry
    is eval {
        bump_version('1.00', 'asdf');
        1
    }, undef, "invalid dir croaks ok";
    like $@, qr/File system entry.*invalid/, "...and error is sane";
}

# file
{
    my $info = get_version_info($f);

    is $info->{$f}, '0.01', "with file, info href contains proper data ok";
}


done_testing();

