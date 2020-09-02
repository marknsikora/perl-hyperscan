package Hyperscan::Scratch;

# ABSTRACT: scratch class

use strict;
use warnings;

use Hyperscan;

1;

__END__

=head2 METHODS

=head3 clone()

Allocate a scratch space that is a clone of an existing scratch space.

L<hs_clone_scratch|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_clone_scratch>

=head3 size()

Provides the size of the given scratch space.

L<hs_scratch_size|https://intel.github.io/hyperscan/dev-reference/api_files.html#c.hs_scratch_size>
