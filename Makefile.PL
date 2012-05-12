use strict;
use warnings;
use ExtUtils::MakeMaker;
use Getopt::Long;	# Technique courtesy of and inspired by IO::Lambda
use IO::Socket::INET;

my $online_tests;

if($ENV{RELEASE_TESTING}) {
	$online_tests = 1;
} else {
	Getopt::Long::GetOptions('online-tests!' => \$online_tests);

	unless(defined($online_tests)) {
		my $s = IO::Socket::INET->new(
			PeerAddr => 'www.google.com:80',
			Timeout => 10
		);
		if($s) {
			close($s);

			print <<EOF;

You appear to be directly connected to the Internet.  I have some tests
that try to query Whois servers.

EOF
			$online_tests = prompt('Do you want to enable these tests?', 'y') =~ /^y/i ? 1 : 0;
		}
	}
}

if($online_tests) {
	open(my $enabled, '>', 't/online.enabled') || die "Can't touch t/online.enabled $!";
	close($enabled) || die "Can't touch t/online.enabled $!";
} else {
	unlink('t/online.enabled');
}

WriteMakefile(
    NAME                => 'CGI::Lingua',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Lingua.pm',
    ABSTRACT_FROM       => 'lib/CGI/Lingua.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::Requires' => 0,
	'Test::NoWarnings' => 0,
	'Locale::Object::Country' => 0,
	'I18N::AcceptLanguage' => 0,
	'Locale::Language' => 0,
	'I18N::LangTags::Detect' => 0,
	'Data::Validate::IP' => 0,
	'Net::Whois::IANA' => 0,
	'Net::Whois::IP' => 0,
	'Class::Load' => 0,
	'CGI::Info' => 0,
	'Sys::Syslog' => 0,
	'HTTP::BrowserDetect' => 0,
	'Test::Kwalitee' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Lingua-* t/online.enabled' },
);
