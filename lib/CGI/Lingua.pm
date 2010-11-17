package CGI::Lingua;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = 0.04;

=head1 NAME

CGI::Lingua - Natural language choices for CGI programs

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

CGI::Lingua provides a simple basis to determine which language to display a website in.
The website tells CGI::Lingua which languages it supports. Based on that list CGI::Lingua
tells the application which language the user would like to use.

    use CGI::Lingua;

    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
    my $language = CGI::Lingua->language();
    if ($language eq 'English') {
       print '<P>Hello</P>';
    } elsif($language eq 'French') {
	print '<P>Bonjour</P>';
    } else {	# $language eq 'Unknown'
	my $rl = CGI::Lingua->requested_language();
	print "<P>Sorry for now this page is not available in $rl.</P>";
    }
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Lingua object.
Takes one parameter: a list of languages, in RFC-1766 format, that the website supports.
Language codes are of the form primary-code [ - country-code ] e.g. 'en', 'en-gb' for English and British English respectively.

For a list of primary-codes refer to ISO-936.
For a list of country-codes refer to ISO-3166.

    # We support English, French, British and American English, in that order
    my $l = CGI::Lingua(supported => [('en', 'fr', 'en-gb', en-us')]);

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
				# (website) supports
		_rlanguage => undef,	# Requested language
		_slanguage => undef,	# Language that the website should display
		_sublanguage => undef,	# E.g. US for en-US if you want American English
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

	if($self->{_slanguage}) {
		return $self->{_slanguage};
	}
	$self->_find_language();
	return $self->{_slanguage};
}

=head2 sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom'.

=cut

sub sublanguage {
	my $self = shift;

	if($self->{_sublanguage}) {
		return $self->{_sublanguage};
	}
	$self->_find_language();
	return $self->{_sublanguage};
}

=head2 requested_language

Gives a human readable rendition of what language the user asked for whether
or not it is supported.

=cut

sub requested_language {
	my $self = shift;

	if($self->{_rlanguage}) {
		return $self->{_rlanguage};
	}
	$self->_find_language();
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

                our $l = I18N::AcceptLanguage->new()->accepts($ENV{'HTTP_ACCEPT_LANGUAGE'}, $self->{_supported});
                if($l) {
                        $self->{_slanguage} = Locale::Language::code2language($l);
                        if($self->{_slanguage}) {
                                $self->{_rlanguage} = $self->{_slanguage};
                                return;
                        }
                        if($l =~ /(.+)-(.+)/) {
                                $l = I18N::AcceptLanguage->new()->accepts($1, $self->{_supported});
                                if($l) {
                                        $self->{_slanguage} = Locale::Language::code2language($l);
                                        if($self->{_slanguage}) {
                                                $self->{_sublanguage} = Locale::Object::Country->new(code_alpha2 => $2)->name;
                                                if($self->{_sublanguage}) {
                                                        $self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
                                                }
                                                return;
                                        }
                                }
                       }
                }
                require I18N::LangTags::Detect;
                $self->{_rlanguage} = I18N::LangTags::Detect::detect();
                if($self->{_rlanguage}) {
                        my $l = Locale::Language::code2language($self->{_rlanguage});
			if($l) {
				$self->{_rlanguage} = $l;
			} else {
				if($self->{_rlanguage} =~ /(.+)-(.+)/) {
					$self->{_rlanguage} = "$1 (" . Locale::Object::Country->new(code_alpha2 => $2)->name . ')';
				}
			}
			return;
                }
		$self->{_rlanguage} = 'Unknown';
        }

        # The client hasn't said which to use, guess from their IP address
        if($ENV{'REMOTE_ADDR'}) {
                require Data::Validate::IP;
                require Net::Whois::IANA;

                Data::Validate::IP->import;
                Net::Whois::IANA->import;

                our $ip = $ENV{'REMOTE_ADDR'};

                unless($ip) {
                        return;
                }
                unless(is_ipv4($ip)) {
                        carp "Unexpected IP $ip\n";
                        return;
                }

                # Translate country to first official language
                our $iana = new Net::Whois::IANA;
                $iana->whois_query(-ip => $ip);
                our $country = lc($iana->country());
                # our $country = lc(Net::Whois::IP::whoisip_query($ip)->{'Country'});
                $self->{_rlanguage} = (Locale::Object::Country->new(code_alpha2 => $country)->languages_official)[0]->name;
		unless((exists($self->{_slanguage})) && ($self->{_slanguage} ne 'Unknown')) {
			$self->{_slanguage} = $self->{_rlanguage};
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

Copyright 2010 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Lingua
