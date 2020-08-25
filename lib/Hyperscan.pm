package Hyperscan;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load( 'Hyperscan', $VERSION );

use Hyperscan::Database;
use Hyperscan::Scratch;
use Hyperscan::Stream;

1;
