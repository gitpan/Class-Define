#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Define' );
}

diag( "Testing Class::Define $Class::Define::VERSION, Perl $], $^X" );
