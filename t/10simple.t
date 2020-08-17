use Test::Most tests => 13;

use Hyperscan::Database;
use Hyperscan::Scratch;

my $db;
my $scratch;

# Compiling a simple expression works
lives_ok { $db = Hyperscan::Database->compile("a|b", 0, 1) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;

# Compiling an unsupported expression (backref) dies
dies_ok { $db = Hyperscan::Database->compile("\\1", 0, 1) };

# Literal expression with a null character
lives_ok { $db = Hyperscan::Database->compile_lit("\0", 0, 1) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;

# Make and use a scratch buffer
lives_ok { $db = Hyperscan::Database->compile("word", 0, 1) };
isa_ok $db, "Hyperscan::Database";
ok $db->size() > 0;
lives_ok { $scratch = Hyperscan::Scratch->new($db) };
isa_ok $scratch, "Hyperscan::Scratch";
lives_ok { $db->scan("a line with a word in it", 0, $scratch) };

# Force (hopefully) deallocation
undef $scratch;
undef $db;
