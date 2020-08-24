package Hyperscan::Util;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(re_flags_to_hs_flags);

use Carp;

use Hyperscan;

sub re_flags_to_hs_flags {
    my ($flags) = @_;

    my $i = 0;
    foreach my $char ( split //, $flags ) {
        if ( $char eq "i" ) {
            $i |= Hyperscan::HS_FLAG_CASELESS;
        }
        elsif ( $char eq "s" ) {
            $i |= Hyperscan::HS_FLAG_DOTALL;
        }
        elsif ( $char eq "m" ) {
            $i |= Hyperscan::HS_FLAG_MULTILINE;
        }
        else {
            carp "unsupported flag $char on regex";
        }
    }

    return $i;
}

1;
