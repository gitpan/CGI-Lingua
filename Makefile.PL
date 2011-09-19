use strict;
use warnings;
use ExtUtils::MakeMaker;

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
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Lingua-*' },
);
