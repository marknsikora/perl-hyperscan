use Test::Most tests => 18;

use Hyperscan;
use Hyperscan::Database;

my $db;
my $scratch;
my @matches;

# Compiling a simple expression works
lives_ok { $db = Hyperscan::Database->compile("a|b", 0, Hyperscan::HS_MODE_BLOCK) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;

# Compiling an unsupported expression (backref) dies
dies_ok { $db = Hyperscan::Database->compile("\\1", 0, Hyperscan::HS_MODE_BLOCK) };

# Literal expression with a null character
lives_ok { $db = Hyperscan::Database->compile_lit("\0", 0, Hyperscan::HS_MODE_BLOCK) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;

# Make and use a scratch buffer
lives_ok { $db = Hyperscan::Database->compile("word", Hyperscan::HS_FLAG_SOM_LEFTMOST, Hyperscan::HS_MODE_BLOCK) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;
lives_ok { $scratch = $db->alloc_scratch(); };
isa_ok $scratch, "Hyperscan::Scratch";
@matches = $db->scan("a line with a word in it", 0, $scratch);
is_deeply \@matches, [{id => 0, from => 14, to => 18, flags => 0}];

# Make a multi match database
lives_ok { $db = Hyperscan::Database->compile_multi(["one word", "two words"], [Hyperscan::HS_FLAG_SOM_LEFTMOST, Hyperscan::HS_FLAG_SOM_LEFTMOST], [0, 1], Hyperscan::HS_MODE_BLOCK) };
isa_ok $db, "Hyperscan::Database";
lives_ok { $scratch = $db->alloc_scratch() };
isa_ok $scratch, "Hyperscan::Scratch";
@matches = $db->scan("a line with one word and two words in it", 0, $scratch);
is_deeply \@matches, [{id => 0, from => 12, to => 20, flags => 0}, {id => 1, from => 25, to => 34, flags => 0}];

# Force (hopefully) deallocation
undef $scratch;
undef $db;
