#!perl -Tw

use strict;
use warnings;
use Test::More tests => 10;
use CGI::Lingua;

HONG_KONG: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
        $ENV{'REMOTE_ADDR'} = "218.213.130.87";
	my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'Chinese');
	ok($l->language() eq 'Unknown');

	$l = CGI::Lingua->new(supported => ['zh']);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'Chinese');
	ok($l->language() eq 'Chinese');
}
