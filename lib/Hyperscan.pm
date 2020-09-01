package Hyperscan;

use strict;
use warnings;

require XSLoader;
XSLoader::load( 'Hyperscan', $Hyperscan::VERSION );

use Hyperscan::Database;
use Hyperscan::Scratch;
use Hyperscan::Stream;

1;

__END__

=head1 NAME

Hyperscan - Perl bindings to the Intel hyperscan regular expression library
