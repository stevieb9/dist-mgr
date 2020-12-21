use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use Module::Bump::Version qw(:all);

my $d = 't/data/orig';
my $f = 't/data/orig/No.pm';

my $h = Hook::Output::Tiny->new;

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

    # invalid fs entry
    is eval {
        bump_version('1.00', 'asdf');
        1
    }, undef, "invalid file system entry croaks ok";
    like $@, qr/File system.*invalid/, "...and error is sane";
}

# Bad/No warnings check
{
    $h->hook('stderr');
    my $data = bump_version('3.77', $d);
    $h->unhook('stderr');

    my @err = $h->stderr;

    is scalar @err, 2, "proper warning count ok";

    like $err[0], qr/No\.pm: Can't find a \$V/, "...and warning is sane";
    like $err[1], qr/Bad\.pm: Can't find a valid/, "...and warning is sane";

    is $data->{"$d/One.pm"}{from}, '0.01', "One has proper from ver";
    is $data->{"$d/One.pm"}{to},   '3.77', "One has proper to ver";

    is $data->{"$d/Two.pm"}{from}, '2.00', "Two has proper from ver";
    is $data->{"$d/Two.pm"}{to},   '3.77', "Two has proper to ver";

    is $data->{"$d/Three.pm"}{from}, '3.00', "Three has proper from ver";
    is $data->{"$d/Three.pm"}{to},   '3.77', "Three has proper to ver";
}

done_testing();

