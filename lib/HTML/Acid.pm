package HTML::Acid;
use base HTML::Parser;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

# Module implementation here

# Buffers
my $out = "";

sub new {
    my $class = shift;
    my $self = HTML::Parser->new;
    bless $self, $class;
    return $self;
}

sub burn {
    my $self = shift;
    my $text = shift;
    $self->parse($text);
    $self->eof;
    return $out;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

HTML::Acid - Reformat HTML fragment to strict criteria

=head1 VERSION

This document describes HTML::Acid version 0.0.1

=head1 SYNOPSIS

    use HTML::Acid;
    my $acid = HTML::Acid->new;
    return $acid->burn($html)
  
=head1 DESCRIPTION

Fragments of HTML returned by a rich text editor tend to be not entirely
standards compliant. C<img> tags tend not to be closed. Paragraphs breaks 
might be represented by double C<br> tags rather than C<p> tags. Of course
we also need to do all the XSS avoidance an HTML clean up routine would,
such as controlling C<href> tags, removing javascript and inline styling.

So this module, given a fragment of HTML, will rewrite it into a very
restricted subset of XHTML.

=over

=item * In this dialect, documents consist entirely of C<p> elements and
C<h1-6> elements.

=item * Every header will have C<id> attribute automatically generated
from the header contents.

=item * Every paragraph may consist of text, C<a> elements, C<img> elements
and other elements decided by the configuration.

=item * Anchors must have an C<href> attribute matching a regular
expression set in the configuration. By default C<href>s are required to be
internal. They may also have a C<title> attribute.

=item * Images must have C<src>, C<title>, C<alt>, C<height> and C<width>
attributes. The C<src> attribute must match the same regular expression
as C<href>.

=item * All other tags must have no attributes and may only contain text.

=item * Double C<br> elements in the source will be interpreted as paragraph
breaks.

=back

=head1 INTERFACE 

=head2 new

This constructor takes three named parameters.

=over 

=item I<allowed_headers>

This is an array reference of tag names that indicates which elements
will be allowed as headers within the fragment. It defaults to C<h3> 
alone.

=item I<external_regex>

This is a regular expression that controls what C<href> and C<src> tags
are permitted. It defaults to an expression that restricts access to internal
absolute paths with an optional sub-reference.

=item I<other_tags>

This is an array reference to a list of additional tags that might be 
permitted inside paragraphs. It defaults to C<em> and C<strong>.

=back

=head2 burn

This method takes the input HTML as an input and returns the cleaned
up HTML.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

HTML::Acid requires no configuration files or environment variables.

=head1 DEPENDENCIES

This module works by subclassing L<HTML::Parser>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-html-acid@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

There are many other modules that do something similar. Of those I think
the most complete is L<HTML::StriptScripts::Parser>. You can also see
L<HTML::Declaw>, L<HTML::Clean>, L<HTML::Defang>, L<HTML::Restrict>,
L<HTML::Scrubber>, L<HTML::Laundary>, L<HTML::Detoxifier>, L<Marpa::HTML>,
L<HTML::Tidy>. People also often refer to HTML::Santitizer.

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
