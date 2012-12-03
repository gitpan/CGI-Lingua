#!perl -Tw

use strict;
use warnings;
use Test::More tests => 11;

# Check comments in Whois records

BEGIN {
	use_ok('CGI::Lingua');
}

ES_419: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en';
	$ENV{'REMOTE_ADDR'} = '212.49.88.99';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en' ]
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	SKIP: {
		skip 'Tests require Internet access', 4 unless(-e 't/online.enabled');
		ok(defined($l->country()));
		ok($l->country() eq 'eu');
		ok($l->language_code_alpha2() eq 'en');
		ok($l->language() eq 'English');
	}
	ok(defined($l->requested_language()));
	ok($l->requested_language() eq 'English');
	ok(!defined($l->sublanguage()));
}
