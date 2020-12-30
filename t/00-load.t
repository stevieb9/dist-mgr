#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    BAIL_OUT "fail";
    use_ok( 'Dist::Mgr' ) || print "Bail out!\n";
}

diag( "Testing Dist::Mgr $Dist::Mgr::VERSION, Module $], $^X" );
