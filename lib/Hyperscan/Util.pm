package Hyperscan::Util;

# ABSTRACT: utility functions for other Hyperscan modules

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
        elsif ( $char eq "u" ) {
            $i |= Hyperscan::HS_FLAG_UTF8 | Hyperscan::HS_FLAG_UCP;
        }
        else {
            carp "unsupported flag $char on regex";
        }
    }

    return $i;
}

1;

__END__

=head2 FUNCTIONS

=head3 re_flags_to_hs_flags( $flags )

Takes the C<$flags> string and converts it to a int that represents the same
hyperscan flags.
