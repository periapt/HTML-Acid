use strict;
use warnings;
use Carp;
use Test::More tests =>3;
use Test::NoWarnings;
use HTML::Acid::Buffer;

my $acid = HTML::Acid::Buffer->new('blah');
isa_ok($acid, 'HTML::Acid::Buffer', 'is a HTML::Acid::Buffer');
ok(!$acid->active, 'not active yet');
