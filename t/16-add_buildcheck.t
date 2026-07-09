use warnings;
use strict;
use Test::More;

use Dist::Mgr qw(:all);

use lib '.';
use lib 't/lib';
use Helper qw(:all);

# Prepare for the tests
check_skip();
unlink_makefile();
copy_makefile();

my $mf_work = 't/data/work/Makefile.PL';

# bad params
{
    is eval { add_buildcheck(); 1 }, undef, "add_buildcheck() croaks with no type";
    like $@, qr/Usage: add_buildcheck/, "...and the error is sane";

    is eval { add_buildcheck('bogus', $mf_work); 1 }, undef,
        "add_buildcheck() croaks on an invalid type";
    like $@, qr/Usage: add_buildcheck/, "...and the error is sane";

    is
        eval { Dist::Mgr::_makefile_insert_buildcheck('wiringpi'); 1 },
        undef,
        "_makefile_insert_buildcheck() croaks with no makefile";
}

# add_buildcheck('wiringpi')
{
    is add_buildcheck('wiringpi', $mf_work), 0,
        "add_buildcheck('wiringpi') returns 0 ok";

    my $work = _slurp($mf_work);

    like $work, qr/require RPi::Const::BuildCheck;/,
        "...shim require present";
    like $work, qr/RPi::Const::BuildCheck::wiringpi_build_check\(\);/,
        "...calls the wiringpi check";
    like $work, qr/exit 0 if ! \$ENV\{RPI_DIST_RELEASE\};/,
        "...keeps the NA-not-FAIL exit";
    like $work, qr/'RPi::Const'\s+=> '1.07',/,
        "...adds RPi::Const to CONFIGURE_REQUIRES";

    # The shim must sit BEFORE WriteMakefile so it can exit before a Makefile
    # is written.
    like $work, qr/require RPi::Const::BuildCheck;.*WriteMakefile\(/s,
        "...shim precedes WriteMakefile()";

    # The generated Makefile.PL must be valid Perl.
    my $err = `$^X -c $mf_work 2>&1`;
    like $err, qr/syntax OK/, "...generated Makefile.PL is valid Perl";
}

# 2nd attempt is idempotent
{
    is add_buildcheck('wiringpi', $mf_work), -1,
        "add_buildcheck() returns -1 when the shim is already present";

    my $work = _slurp($mf_work);

    my $shims = () = $work =~ /require RPi::Const::BuildCheck;/g;
    is $shims, 1, "...the shim was not duplicated";

    my $reqs = () = $work =~ /'RPi::Const'\s+=> '1.07',/g;
    is $reqs, 1, "...the CONFIGURE_REQUIRES entry was not duplicated";
}

# the i2c variant emits the i2c check
{
    unlink_makefile();
    copy_makefile();

    is add_buildcheck('i2c', $mf_work), 0, "add_buildcheck('i2c') returns 0 ok";

    my $work = _slurp($mf_work);

    like $work, qr/RPi::Const::BuildCheck::i2c_build_check\(\);/,
        "...calls the i2c check";
    unlike $work, qr/wiringpi_build_check/,
        "...and not the wiringpi check";
}

unlink_makefile();

done_testing();

sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "$file: $!";
    local $/;
    return <$fh>;
}
