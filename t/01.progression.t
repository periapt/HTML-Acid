use strict;
use warnings;
use Carp;
use Test::More;
use Test::NoWarnings;
use HTML::Acid;
use Readonly;

Readonly my @INPUT_FILES => glob 't/in/*';
plan tests => 5+@INPUT_FILES;

my $acid = HTML::Acid->new;
isa_ok($acid, 'HTML::Acid', 'is a HTML::Acid');
isa_ok($acid, 'HTML::Parser', 'is a HTML::Parser');
ok($acid->can('burn'), 'Acid can burn.');
is($acid->burn(''), '', 'really trivial stuff');

foreach my $input (@INPUT_FILES) {
    subtest $input => sub {
        plan tests => 1;
        pass;
    }
}

