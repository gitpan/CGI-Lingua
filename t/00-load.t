#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Lingua' ) || print "Bail out!
";
}

diag( "Testing CGI::Lingua $CGI::Lingua::VERSION, Perl $], $^X" );
