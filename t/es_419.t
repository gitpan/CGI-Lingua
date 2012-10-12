#!perl -Tw

use strict;
use warnings;
use Test::More tests => 9;

# Doesn't handle es-419 fully

BEGIN {
	use_ok('CGI::Lingua');
}

RT69509: {
	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}

	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'es-419,es;q=0.8';
	$ENV{'REMOTE_ADDR'} = '201.213.196.117';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'fr-fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr', 'es-419'],
	]);
	ok(defined $l);
	ok($l->isa('CGI::Lingua'));
	ok($l->country() eq 'ar');
	ok($l->language_code_alpha2() eq 'es');
	ok(defined($l->requested_language()));
	ok($l->language() eq 'Spanish');
	TODO: {
		local $TODO = "sublanguage doesn't handle 3 characters";

		ok(defined($l->sublanguage()));
	};
}
