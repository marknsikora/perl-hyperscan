package Hyperscan::Matcher;
use strict;
use warnings;

use Carp;
use re qw(regexp_pattern);

use Hyperscan;
use Hyperscan::Database;
use Hyperscan::Util qw(re_flags_to_hs_flags);

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize {
    my $self = shift;

    my $specs = shift;
    my %args  = @_;

    my $literal = defined $args{literal} ? $args{literal} : 0;
    my $default_flags =
      defined $args{default_flags}
      ? $args{default_flags}
      : Hyperscan::HS_FLAG_SOM_LEFTMOST;

    my $mode = defined $args{mode} ? $args{mode} : "block";

    if ( $mode eq "block" ) {
        $mode = Hyperscan::HS_MODE_BLOCK;
    }
    elsif ( $mode eq "stream" ) {
        $mode = Hyperscan::HS_MODE_STREAM;
    }
    elsif ( $mode eq "vectored" ) {
        $mode = Hyperscan::HS_MODE_VECTORED;
    }
    else {
        croak "unknown mode $mode";
    }

    my @expressions;
    my @flags;
    my @ids;
    my @ext;

    for ( my $id = 0 ; $id <= $#{$specs} ; $id++ ) {
        my $spec = $specs->[$id];
        if ( ref $spec eq "" ) {
            push @expressions, $spec;
            push @flags,       $default_flags;
            push @ids,         $id;
            push @ext,         undef;
        }
        elsif ( ref $spec eq "REGEXP" || ref $spec eq "Regexp" ) {
            my ( $pat, $mod ) = regexp_pattern($spec);

            my $flag = $default_flags;
            $flag |= re_flags_to_hs_flags($mod);

            push @expressions, $pat;
            push @flags,       $flag;
            push @ids,         $id;
            push @ext,         undef;
        }
        elsif ( ref $spec eq "ARRAY" ) {
            my $pat = shift @{$spec};

            my $flag = $default_flags;
            if ( ref $spec eq "REGEXP" || ref $spec eq "Regexp" ) {
                my $mod;
                ( $pat, $mod ) = regexp_pattern($pat);

                $flag |= re_flags_to_hs_flags($mod);
            }
            else {
                $flag = shift @{$spec};
            }

            push @expressions, $pat;
            push @flags,       $flag;

            my $explicit_id = shift @{$spec};
            push @ids, defined $explicit_id ? $explicit_id : $id;

            push @ext, ( shift @{$spec} );
        }
        elsif ( ref $spec eq "HASH" ) {
        }
        else {
            carp "unknown ref type ", ref $spec, $spec;
        }
    }

    my $has_ext = grep { defined } @ext;
    my $count   = scalar @expressions;

    if ($literal) {
        croak "can't use both ext and literal"
          if $has_ext;

        if ( $count == 1 ) {
            $self->{db} =
              Hyperscan::Database->compile_lit( @expressions, @flags, $mode );
        }
        else {
            $self->{db} =
              Hyperscan::Database->compile_lit_multi( \@expressions, \@flags,
                \@ids, $mode );
        }
    }
    else {
        if ($has_ext) {
            $self->{db} =
              Hyperscan::Database->compile_ext_multi( \@expressions, \@flags,
                \@ids, \@ext, $mode );
        }
        else {
            if ( $count == 1 ) {
                $self->{db} =
                  Hyperscan::Database->compile( @expressions, @flags, $mode );
            }
            else {
                $self->{db} =
                  Hyperscan::Database->compile_multi( \@expressions, \@flags,
                    \@ids, $mode );
            }
        }
    }

    $self->{scratch} = $self->{db}->alloc_scratch();

    if ( $mode == Hyperscan::HS_MODE_STREAM ) {
        $self->{stream} = $self->{db}->open_stream();
    }

    $self->{mode} = $mode;

    return;
}

sub scan {
    my $self = shift;

    my $data = shift;

    my $flags = shift;
    $flags = Hyperscan::HS_MODE_SOM_HORIZON_SMALL if not defined $flags;

    if ( $self->{mode} == Hyperscan::HS_MODE_BLOCK ) {
        return $self->{db}->scan( $data, $flags, $self->{scratch} );
    }
    elsif ( $self->{mode} == Hyperscan::HS_MODE_STREAM ) {
        return $self->{stream}->scan( $data, $flags, $self->{scratch} );
    }
    elsif ( $self->{mode} == Hyperscan::HS_MODE_VECTORED ) {
        return $self->{db}->scan_vector( $data, $flags, $self->{scratch} );
    }
    else {
        croak "unknown mode $self->{mode}";
    }
}

1;
