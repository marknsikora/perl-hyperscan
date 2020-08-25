use Test::Most tests => 6;

use Hyperscan;
use Hyperscan::Database;

my $db;
my $bytes;
my $scratch;
my @matches;

lives_ok {
    $db = Hyperscan::Database->compile( "a|b", 0, Hyperscan::HS_MODE_BLOCK )
};
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;
$bytes = $db->serialize();
ok length $bytes > 0;
$db = Hyperscan::Database->deserialize($bytes);
isa_ok $db, "Hyperscan::Database";
$scratch = $db->alloc_scratch();
@matches = $db->scan( "a", 0, $scratch );
is_deeply \@matches, [ { id => 0, from => 0, to => 1, flags => 0 } ];
