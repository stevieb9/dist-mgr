#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Module::Bump::Version' ) || print "Bail out!\n";
}

diag( "Testing Module::Bump::Version $Module::Bump::Version::VERSION, Module $], $^X" );
