use Test::Most tests => 2;

use Hyperscan::Matcher;

my $matcher;
my @matches;

$matcher = Hyperscan::Matcher->new( [ "word", qr/Pattern/i ] );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan("a word for the pattern to match");
is_deeply \@matches,
  [
    { id => 0, from => 2,  to => 6,  flags => 0 },
    { id => 1, from => 15, to => 22, flags => 0 }
  ];
