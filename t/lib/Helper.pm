package Helper;

use warnings;
use strict;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(trap);

sub trap {
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
1;