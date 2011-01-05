package CGI::Lingua;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
our $VERSION = '0.13';
$VERSION = eval $VERSION;

=head1 NAME

CGI::Lingua - Natural language choices for CGI programs

=head1 VERSION

Version 0.13

=cut

=head1 SYNOPSIS

CGI::Lingua provides a simple basis to determine which language to display a website in.
The website tells CGI::Lingua which languages it supports. Based on that list CGI::Lingua
tells the application which language the user would like to use.

    use CGI::Lingua;

    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
    my $language = $l->language();
    if ($language eq 'English') {
       print '<P>Hello</P>';
    } elsif($language eq 'French') {
	print '<P>Bonjour</P>';
    } else {	# $language eq 'Unknown'
	my $rl = $l->requested_language();
	print "<P>Sorry for now this page is not available in $rl.</P>";
    }

    ...

    use CHI;
    use CGI::Lingua;

    my $cache = (CHI->new(driver => 'File'));
    my $l = CGI::Lingua->new(supported => ['en', 'fr], cache => $cache);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Lingua object.

Takes one mandatory parameter: a list of languages, in RFC-1766 format, that the website supports.
Language codes are of the form primary-code [ - country-code ] e.g. 'en', 'en-gb' for English and British English respectively.

For a list of primary-codes refer to ISO-936.
For a list of country-codes refer to ISO-3166.

    # We support English, French, British and American English, in that order
    my $l = CGI::Lingua(supported => [('en', 'fr', 'en-gb', en-us')]);

Takes one optional parameter, a CHI object which is used to cache Whois lookups.

=cut

sub new {
	my ($class, %params) = @_;

	# TODO: check that the number of supported languages is > 0
	# unless($params{supported} && ($#params{supported} > 0)) {
		# croak('You must give a list of supported languages');
	# }
	unless($params{supported}) {
		croak('You must give a list of supported languages');
	}

	my $self = {
		_supported => $params{supported}, # List of languages (two letters) that the application
		_cache => $params{cache},	# CHI
				# (website) supports
		_rlanguage => undef,	# Requested language
		_slanguage => undef,	# Language that the website should display
		_sublanguage => undef,	# E.g. US for en-US if you want American English
		_slanguage_code_alpha2 => undef, # E.g en, fr
	};
	bless $self, $class;

	return $self;
}

=head2 language

Tells the CGI application what language to display its messages in.
The language is the natural name e.g. 'English' or 'Japanese'.

=cut

sub language {
	my $self = shift;

	unless($self->{_slanguage}) {
		$self->_find_language();
	}
	return $self->{_slanguage};
}

=head2 name

Synonym for language, for compatibilty with Local::Object::Language

=cut

sub name {
	my $self = shift;

	return $self->language();
}

=head2 sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom'.

=cut

sub sublanguage {
	my $self = shift;

	unless($self->{_sublanguage}) {
		$self->_find_language();
	}
	return $self->{_sublanguage};
}

=head2 code_alpha2

Gives the two character representation of the supported language, e.g. 'en'.

=cut

sub code_alpha2 {
	my $self = shift;

	unless($self->{_slanguage_code_alpha2}) {
		$self->_find_language();
	}
	return $self->{_slanguage_code_alpha2};
}

=head2 requested_language

Gives a human readable rendition of what language the user asked for whether
or not it is supported.

=cut

sub requested_language {
	my $self = shift;

	unless($self->{_rlanguage}) {
		$self->_find_language();
	}
	return $self->{_rlanguage};
}

sub _find_language {
	my $self = shift;

	$self->{_rlanguage} = 'Unknown';
	$self->{_slanguage} = 'Unknown';

	require Locale::Object::Country;
	Locale::Object::Country->import;

	# Use what the client has said
	if($ENV{'HTTP_ACCEPT_LANGUAGE'}) {
		require I18N::AcceptLanguage;
		require Locale::Language;

		I18N::AcceptLanguage->import;
		Locale::Language->import;

		my $l = I18N::AcceptLanguage->new()->accepts($ENV{'HTTP_ACCEPT_LANGUAGE'}, $self->{_supported});
		if($l) {
			$self->{_slanguage} = Locale::Language::code2language($l);
			if($self->{_slanguage}) {
				$self->{_slanguage_code_alpha2} = $l;
				$self->{_rlanguage} = $self->{_slanguage};
				return;
			}
			if($l =~ /(.+)-(.+)/) {
				$l = I18N::AcceptLanguage->new()->accepts($1, $self->{_supported});
				if($l) {
					$self->{_slanguage} = Locale::Language::code2language($l);
					if($self->{_slanguage}) {
						$self->{_slanguage_code_alpha2} = $l;
						$self->{_sublanguage} = Locale::Object::Country->new(code_alpha2 => $2)->name;
						if($self->{_sublanguage}) {
							$self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
						}
						return;
					}
				}
		       }
		}
		# if($self->{_slanguage}) {
			require I18N::LangTags::Detect;
			$self->{_rlanguage} = I18N::LangTags::Detect::detect();
			if($self->{_rlanguage}) {
				my $l = Locale::Language::code2language($self->{_rlanguage});
				if($l) {
					$self->{_rlanguage} = $l;
				} else {
					if($self->{_rlanguage} =~ /(.+)-(.+)/) {
						my $l = Locale::Language::code2language($1);
						unless($l) {
							$l = $1;
						}
						$self->{_rlanguage} = "$l (" . Locale::Object::Country->new(code_alpha2 => $2)->name . ')';
					}
				}
				return;
			}
		# }
		$self->{_rlanguage} = 'Unknown';
		$self->{_slanguage} = 'Unknown';
	}

	# The client hasn't said which to use, guess from their IP address
	# TODO: Whois look ups can be slow - add cache?
	if($ENV{'REMOTE_ADDR'}) {
		my $ip = $ENV{'REMOTE_ADDR'};

		unless($ip) {
			return;
		}
		require Data::Validate::IP;
		Data::Validate::IP->import;

		unless(is_ipv4($ip)) {
			carp "Unexpected IP $ip\n";
			return;
		}

		my $country;

		if($self->{_cache}) {
			$country = $self->{_cache}->get($ip);

		}
		unless(defined $country) {
			require Net::Whois::IANA;
			Net::Whois::IANA->import;

			# Translate country to first official language

			my $iana = new Net::Whois::IANA;
			$iana->whois_query(-ip => $ip);

			$country = $iana->country();
			if($country) {
				$country = lc($country);
			} else {
				require Net::Whois::IP;
				Net::Whois::IP->import;

				$country = lc(Net::Whois::IP::whoisip_query($ip)->{'Country'});
			}
		}
		if($country eq 'hk') {
			# Hong Kong is no longer a country, but Whois thinks
			# it is - try "whois 218.213.130.87"
			$country = 'cn';
		}
		my $l = (Locale::Object::Country->new(code_alpha2 => $country)->languages_official)[0];
		if($l && $l->name) {
			$self->{_rlanguage} = $l->name;
			unless((exists($self->{_slanguage})) && ($self->{_slanguage} ne 'Unknown')) {
				# Check if the language is one that we support
				# Don't bother with secondary language
				require Locale::Language;

				Locale::Language->import;

				my $code = Locale::Language::language2code($self->{_rlanguage});
				foreach (@{$self->{_supported}}) {
					my $s;
					if($_ =~ /^(.+)-.+/) {
						$s = $1;
					} else {
						$s = $_;
					}
					if($code eq $s) {
						$self->{_slanguage} = $self->{_rlanguage};
						$self->{_slanguage_code_alpha2} = $l->code_alpha2;
						last;
					}
				}
			}
			if($self->{_cache}) {
				$country = $self->{_cache}->set($ip, $country, 600);
			}
		} else {
			carp("Can't determine language from IP $ip, country $country");
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-lingua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Lingua


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Lingua>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Lingua>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Lingua/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of CGI::Lingua
