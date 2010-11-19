#!perl -Tw

use strict;
use warnings;
use Test::More tests => 25;

BEGIN {
	use_ok('CGI::Lingua');
}

LANGUAGES: {
	eval {
		CGI::Lingua->new();
	};
	ok($@ =~ m/You must give a list of supported languages/);

	$ENV{'LANGUAGE'} = undef;
	$ENV{'LC_ALL'} = undef;
	$ENV{'LC_MESSAGES'} = undef;
	$ENV{'LANG'} = undef;

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = undef;
        $ENV{'REMOTE_ADDR'} = undef;
	my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok($l->requested_language() eq 'Unknown');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb,en;q=0.5';
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'English');
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'English (United Kingdom)');

	$l = CGI::Lingua->new(supported => ['de', 'fr']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'Unknown');

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'zz';
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'Unknown');
	ok(defined $l->requested_language());

        $ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->language() eq 'English');
	ok(defined $l->requested_language());
	if($l->requested_language() !~ /English/) {
		diag('Expected English requested language, got "' . $l->requested_language() . '"');
	}
	ok($l->requested_language() =~ /English/);
}
