#!perl -Tw

use strict;
use warnings;
use Test::More tests => 12;
use CGI::Lingua;

HONG_KONG: {
	my $cache;

	eval {
		require CHI;

		CHI->import;
	};

	if($@) {
		diag("CHI not installed");
		$cache = undef;
	} else {
		diag("Using CHI $CHI::VERSION");
		my $hash = {};
		$cache = (CHI->new(driver => 'Memory', datastore => $hash));
	}

	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};

        $ENV{'REMOTE_ADDR'} = '218.213.130.87';

	my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us'], cache => $cache);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'Chinese');
	ok(defined $l->language());
	ok($l->language() eq 'Unknown');

	$l = CGI::Lingua->new(supported => ['zh'], cache => $cache);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok(defined $l->requested_language());
	ok($l->requested_language() eq 'Chinese');
	ok(defined $l->language());
	ok($l->language() eq 'Chinese');
}
