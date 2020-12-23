use warnings;
use strict;

use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $f = 't/data/orig/One.pm';
my $f_bad = 't/data/orig/Bad.pm';
my $f_no = 't/data/orig/No.pm';

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

# dir
{
    trap_warn(1);
    my $info = get_version_info($d);
    trap_warn(0);

    is keys %$info, 5, "proper key count in info href ok";

    is $info->{"$d/One.pm"}, '0.01', "One.pm has proper version ok";
    is $info->{"$d/Two.pm"}, '2.00', "Two.pm has proper version ok";
    is $info->{"$d/Three.pm"}, '3.00', "Three.pm has proper version ok";
    is $info->{"$d/Bad.pm"}, undef, "Bad.pm has undef version ok";
    is $info->{"$d/No.pm"}, undef, "No.pm has undef version ok";

}

# bad version
{
    my $h = Hook::Output::Tiny->new;

    $h->hook('stderr');
    get_version_info($d);
    $h->unhook('stderr');

    my @stderr = $h->stderr;

    my $no = grep {'VERSIONx definition'} @stderr;

#    warn Dumper \@stderr;
    is grep(/No.pm.*\$VERSION definition/, @stderr), 1, "No.pm croaks about no ver def ok";
#    is ((grep /Bad\.pm.*valid version/, @stderr), 1, "Bad.pm croaks about no valid ver ok";);

#    like $stderr[0], qr/No\.pm.*\$VERSION definitiontest
    # /, "No.pm croaks about no ver def ok";
#    like $stderr[1], qr/Bad\.pm.*valid version/, "Bad.pm croaks about no valid ver ok";

}

done_testing();

