#!perl -Tw

use strict;
use warnings;
use Test::More tests => 10;

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
	ok($l->locale()->currency()->code() eq 'USD');

	$ENV{'REMOTE_ADDR'} = '212.159.106.41';
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET4.0C; .NET4.0E)';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-gb']
	]);
	ok(defined($l->locale()));
	ok($l->locale()->currency()->code() eq 'GBP');

        delete $ENV{'REMOTE_ADDR'};
	$ENV{'HTTP_USER_AGENT'} = 'Java';
	$l = new_ok('CGI::Lingua' => [
		supported => ['en', 'en-us']
	]);
	ok(!defined($l->locale()));
}
