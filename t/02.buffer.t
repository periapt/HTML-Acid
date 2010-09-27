use strict;
use warnings;
use Carp;
use Test::More tests =>9;
use Test::NoWarnings;
use HTML::Acid::Buffer;

my $acid = HTML::Acid::Buffer->new('blah');
isa_ok($acid, 'HTML::Acid::Buffer', 'is a HTML::Acid::Buffer');
ok(!$acid->active, 'not active yet');

$acid->start(class=>'xxx',id=>'yyy');
ok($acid->active, 'active now');
is($acid->state, '', 'empty state');

$acid->add('This is a ');
ok($acid->active, 'active now');
is($acid->state, 'This is a ', 'empty state');

$acid->add('cool sentence.');
ok($acid->active, 'active now');
is($acid->state, 'This is a cool sentence.', 'empty state');

