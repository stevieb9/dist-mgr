#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Perl::Bump::Version' ) || print "Bail out!\n";
}

diag( "Testing Perl::Bump::Version $Perl::Bump::Version::VERSION, Perl $], $^X" );
