use strict;
use warnings;
use Test::More tests => 2;
use ExtUtils::Manifest;

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
##!perl -T
#use 5.006;
#use strict;
#use warnings;
#use Test::More;
#
#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}
#
#my $min_tcm = 0.9;
#eval "use Test::CheckManifest $min_tcm";
#plan skip_all => "Test::CheckManifest $min_tcm required" if $@;
#
#ok_manifest();
