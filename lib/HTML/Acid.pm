package HTML::Acid;
use base HTML::Parser;

use warnings;
use strict;
use Carp;
use Readonly;

use version; our $VERSION = qv('0.0.1');

# Module implementation here

Readonly my %START_HANDLERS => (
    img=>\&_img_start,
    h1=>\&_h_start,
    h2=>\&_h_start,
    h3=>\&_h_start,
    h4=>\&_h_start,
    h5=>\&_h_start,
    h6=>\&_h_start,
#    br=>\&_br_start,
);
Readonly my %END_HANDLERS => (
    img=>\&_null,
    h1=>\&_h_end,
    h2=>\&_h_end,
    h3=>\&_h_end,
    h4=>\&_h_end,
    h5=>\&_h_end,
    h6=>\&_h_end,
);

sub new {
    my $class = shift;
    my $tag_hierarchy = shift || $class->default_tag_hierarchy;

    # Configue HTML::Prser options
    my $self = HTML::Parser->new(
        api_version => 3,
        empty_element_tags=>1,
        strict_comment=>1,
    );

    # Set up HTML::Parser handlers
    $self->handler(text=>'_text_process', 'self,dtext');
    $self->handler(start=>'_start_process', 'self,tagname,attr');
    $self->handler(end=>'_end_process', 'self,tagname');
    $self->handler(end_document=>'_end_document', 'self');
    $self->handler(start_document=>'_reset', 'self');

    # Bypass as much as possible
    $self->ignore_elements('script','style');
    my @tags = sort {
        # sort like this so that the later depth calcs do not
        # loop for ever.
        $tag_hierarchy->{$a} cmp $tag_hierarchy->{$b}
    } keys %$tag_hierarchy;
    $self->report_tags(@tags, 'br');

    # calculate depths
    $self->{_acid_depths}->{''} = 0;
    while(@tags) {
        my $tag = shift @tags;
        my $value = $tag_hierarchy->{$tag};
        if (exists $self->{_acid_depths}->{$value}) {
            $self->{_acid_depths}->{$tag}
                = $self->{_acid_depths}->{$value} + 1;
        }
        else {
            push @tags, $tag;
        }
    }
    $self->{_acid_hierarchy} = $tag_hierarchy;

    bless $self, $class;
    return $self;
}

sub _null {
}

sub _text_process {
    my $self = shift;
    my $dtext = shift;

    # To add to the buffer unhindered we must not be in the 
    # start state.
    my $actual_state = $self->{_acid_state};
    if ($actual_state eq '' and $dtext =~ /\S/) {
        $self->_start_process('p', {});
    }

    $self->_buffer($dtext);
    return;
}

sub _start_process {
    my $self = shift;
    my $tagname = shift;
    my $attr = shift;

    # To call _start_process unhindered
    # the parent tag of $tagname must be the
    # current state.
    my $required_state = $self->{_acid_hierarchy}->{$tagname};
    my $actual_state = $self->{_acid_state};
    if ($required_state ne $actual_state) {
        my $required_depth = $self->{_acid_depths}->{$required_state};
        my $actual_depth = $self->{_acid_depths}->{$actual_state};
        if ($actual_depth >= $required_depth) {
            $self->_end_process($actual_state);
        }
        if ($required_state) {
            $self->_start_process($required_state, {});
        }
    }

    if (exists $START_HANDLERS{$tagname}) {
        my $callback = $START_HANDLERS{$tagname};
        $self->$callback($tagname,$attr);
    }
    else {
        $self->_buffer("<$tagname");
        foreach my $key (sort keys %$attr) {
            $self->_buffer(" $key=\"$attr->{$key}\"");
        }
        $self->_buffer(">");
    }

    # State shifts to the current tag.
    $self->{_acid_state} = $tagname;

    return;
}

sub _end_process {
    my $self = shift;
    my $tagname = shift;

    # To call _start_process unhindered
    # $tagname must be the current state.
    my $actual_state = $self->{_acid_state};
    if ($tagname ne $actual_state) {
        my $tag_depth = $self->{_acid_depths}->{$tagname};
        my $actual_depth = $self->{_acid_depths}->{$actual_state};
        return if $tag_depth >= $actual_depth;
        $self->_end_process($actual_state);
    }

    if (exists $END_HANDLERS{$tagname}) {
        my $callback = $END_HANDLERS{$tagname};
        $self->$callback($tagname);
    }
    else {
        $self->_buffer("</$tagname>");
    }

    # State shifts to the parent tag.
    $self->{_acid_state} = $self->{_acid_hierarchy}->{$tagname};

    return;
}

sub _end_document {
    my $self = shift;

    # We want to end in the start state.
    my $actual_state = $self->{_acid_state};
    if ($actual_state ne '') {
        $self->_end_process('p');
        $self->_buffer("\n");
    }

    return;
}

sub _img_start {
    my $self = shift;
    my $tagname = shift;
    my $attr = shift;

    return if not my $alt = $attr->{alt};
    if (my $height = $attr->{height} and
        my $width = $attr->{width} and
        my $title = $attr->{title} and
        my $src = $attr->{src}) {
        $self->_buffer("<img alt=\"$alt\" height=\"$height\" src=\"$src\" "
         ."title=\"$title\" width=\"$width\" />");
    }
    else {
       $self->_buffer(" $alt ");
    }
    return;
}

sub _h_start {
    my $self = shift;
    my $tagname = shift;
    my $attr = shift;
    return if not my $id = $attr->{id};
    $self->_buffer("<$tagname id=\"$id\">");
    return;
}

sub _h_end {
    my $self = shift;
    my $tagname = shift;
    $self->_buffer("</$tagname>");
    return;
}

sub _buffer {
    $_[0]->{_acid_buffer} .= $_[1];
    return;
}

sub _reset {
    my $self = shift;
    $self->{_acid_buffer} = "";
    $self->{_acid_state} = "";
    return;
}

sub burn {
    my $self = shift;
    my $text = shift;
    $self->parse($text);
    $self->eof;
    return $self->{_acid_buffer};
}

sub default_tag_hierarchy {
    return {
        h3 => '',
        p => '',
        a => 'p',
        img => 'p',
        em => 'p',
        strong => 'p',
    };
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
Furthermore what one often wants is not simply a standards compliant cleaned
up version of the input HTML. Sometimes one wants to know that the HTML
conforms to a much tighter standard, as then it will be easier to style.

So this module, given a fragment of HTML, will rewrite it into a very
restricted subset of XHTML.

=over

=item * In this dialect, documents consist entirely of C<p> elements and
C<h3> elements.

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

This constructor takes two named parameters.

=over 

=item I<external_regex>

This is a regular expression that controls what C<href> and C<src> tags
are permitted. It defaults to an expression that restricts access to internal
absolute paths with an optional sub-reference.

=item I<tag_hierarchy>

This is a hash reference that for each supported tag specifies what 
the containing tag must be. Standards based HTML is not as strict as this.
This defaults to the value returned by the C<default_tag_hierarchy>
method.

=back

=head2 burn

This method takes the input HTML as an input and returns the cleaned
up HTML.

=head2 default_tag_hierarchy

This is a class method that returns the default tag hierarchy. So if 
you want to add support for a tag you can use a modified copy of the 
output when setting up the L<HTML::Acid> instance. The default
mapping is as follows:

    {
        h3 => '',
        p => '',
        a => 'p',
        img => 'p',
        em => 'p',
        strong => 'p',
    }

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
