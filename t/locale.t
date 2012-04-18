#!perl -Tw

use strict;
use warnings;
use Test::More tests => 29;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Lingua');
}

LANGUAGES: {
	eval {
		CGI::Lingua->new();
	};
	ok($@ =~ m/You must give a list of supported languages/);

	# Stop I18N::LangTags::Detect from detecting something
	delete $ENV{'LANGUAGE'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	delete $ENV{'LANG'};
	if($^O eq 'MSWin32') {
		$ENV{'IGNORE_WIN32_LOCALE'} = 1;
	}
	delete $ENV{'HTTP_ACCEPT_LANGUAGE'};
        delete $ENV{'REMOTE_ADDR'};

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.19) Gecko/20110707 Firefox/3.6.19';
	my $l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-us']
	]);
	ok(defined($l->locale()));
	ok(defined($l->locale()->currency()));
	ok($l->locale()->currency()->code() eq 'USD');

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	ok($l->locale()->currency()->code() eq 'GBP');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
	isa_ok($l->locale, 'Locale::Object::Country');
	my @l = $l->locale()->languages_official();
	ok(uc($l[0]->code_alpha2()) eq 'EN');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');

        delete $ENV{'REMOTE_ADDR'};
	$ENV{'HTTP_USER_AGENT'} = 'Java';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-us']
	]);
	ok(!defined($l->locale()));

	# Asking for French in the US should return US locale
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'fr';
	$ENV{'REMOTE_ADDR'} = '74.92.149.57';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.7; en-US; rv:1.9.2.22) Gecko/20110902 Firefox/3.6.22';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'nl', 'fr', 'de', 'id', 'il', 'ja', 'ko', 'pt', 'ru', 'es', 'tr']
	]);
	ok(defined($l->locale()));
	ok(uc($l->locale()->code_alpha2()) eq 'US');
	isa_ok($l->locale, 'Locale::Object::Country');
	ok(defined($l->locale()->currency()));
	ok($l->locale()->currency()->code() eq 'USD');

	# User agent doesn't contain a location
	$ENV{'REMOTE_ADDR'} = '81.145.173.18';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.2; WOW64; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; MS-RTC LM 8; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';
	$ENV{'HTTP_ACCEPT_LANGUAGE'} = 'en-gb';

	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	ok($l->locale()->currency()->code() eq 'GBP');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
	isa_ok($l->locale, 'Locale::Object::Country');
	@l = $l->locale()->languages_official();
	ok(uc($l[0]->code_alpha2()) eq 'EN');
	ok(uc($l->locale()->code_alpha2()) eq 'GB');
}
