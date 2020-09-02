package Hyperscan;

# ABSTRACT: Perl bindings to the Intel hyperscan regular expression library

use strict;
use warnings;

require XSLoader;
XSLoader::load( 'Hyperscan', $Hyperscan::VERSION );

use Hyperscan::Database;
use Hyperscan::Scratch;
use Hyperscan::Stream;

1;

__END__

=head2 SYNOPSIS

  use Hyperscan::Matcher;

  my $matcher = Hyperscan::Matcher->new([
    "one",
    qr/More/i,
    { expr => "words" },
  ]);
  $matcher->scan("one or more words to match");

=head2 DESCRIPTION

Hyperscan is a set of XS wrappers around the Intel hyperscan library, a
high-performance regular expression matching library. This library contains two
sets of wrappers.

The first is a set of low level wrappers that offer a direct interface to the c
library, albeit with a more Perlish OO interface.

The second is a high level module meant to provide low friction access to the
most common use cases from a Perl script L<Hyperscan::Matcher>.

=head2 FUNCTIONS

=head3 hs_version()

Utility function for identifying underlying hyperscan release version.

=head2 SEE ALSO

=head3 L<Hyperscan::Databse>

=head3 L<Hyperscan::Matcher>

=head3 L<Hyperscan::Scratch>

=head3 L<Hyperscan::Stream>

=head3 L<Hyperscan::Util>
