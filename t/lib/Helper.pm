package Helper;

use warnings;
use strict;

use Carp qw(croak);
use Exporter qw(import);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trap_warn);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub trap_warn {
    # enable/disable sinking our own internal warnings to prevent
    # cluttered test output

    my ($bool) = shift;

    croak("trap() needs a bool param") if ! defined $bool;

    if ($bool) {
        $SIG{__WARN__} = sub {
            my $w = shift;

            if ($w =~ /valid version/ || $w =~ /VERSION definition/) {
                return;
            }
            else {
                warn $w;
            }
        }
    }
    else {
        $SIG{__WARN__} = sub { warn shift; }
    }
}
1;