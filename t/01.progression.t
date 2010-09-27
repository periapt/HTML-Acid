use strict;
use warnings;
use Carp;
use Test::More;
use Test::NoWarnings;
use HTML::Acid;
use Readonly;
use File::Basename;
use Perl6::Slurp;

Readonly my @INPUT_FILES => glob 't/in/*';
plan tests => 5+@INPUT_FILES;

my $acid = HTML::Acid->new;
isa_ok($acid, 'HTML::Acid', 'is a HTML::Acid');
isa_ok($acid, 'HTML::Parser', 'is a HTML::Parser');
ok($acid->can('burn'), 'Acid can burn.');
is($acid->burn(''), '', 'really trivial stuff');

foreach my $input_file (@INPUT_FILES) {
    subtest $input_file => sub {
        plan tests => 1;
        my $input = slurp $input_file;
        my $basename = basename $input_file;
        my $expected = slurp "t/out/$basename";
        my $actual = $acid->burn($input);
        is ($actual, $expected, "expected $input_file");
    }
}

