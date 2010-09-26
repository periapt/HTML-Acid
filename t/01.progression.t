use strict;
use warnings;
use Carp;
use Test::More tests => 4;
use Test::NoWarnings;
use HTML::Acid;

my $acid = HTML::Acid->new;
isa_ok($acid, 'HTML::Acid', 'is a HTML::Acid');
isa_ok($acid, 'HTML::Parser', 'is a HTML::Parser');
ok($acid->can('burn'), 'Acid can burn.');

