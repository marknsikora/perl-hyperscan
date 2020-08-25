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

    $self->{mode} = $mode;

    $mode =
        $mode eq "block" ? Hyperscan::HS_MODE_BLOCK
      : $mode eq "stream"
      ? Hyperscan::HS_MODE_STREAM | Hyperscan::HS_MODE_SOM_HORIZON_LARGE
      : $mode eq "vectored" ? Hyperscan::HS_MODE_VECTORED
      :                       croak "unknown mode $mode";

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
            if ( ref $pat eq "REGEXP" || ref $pat eq "Regexp" ) {
                my $mod;
                ( $pat, $mod ) = regexp_pattern($pat);

                $flag |= re_flags_to_hs_flags($mod);
            }
            else {
                my $tmp = shift @{$spec};
                $flag |= $tmp if defined $tmp;
            }

            push @expressions, $pat;
            push @flags,       $flag;

            my $explicit_id = shift @{$spec};
            push @ids, defined $explicit_id ? $explicit_id : $id;

            push @ext, ( shift @{$spec} );
        }
        elsif ( ref $spec eq "HASH" ) {
            my $pat = $spec->{expr};

            my $flag = $default_flags;
            if ( ref $pat eq "REGEXP" || ref $pat eq "Regexp" ) {
                my $mod;
                ( $pat, $mod ) = regexp_pattern($pat);

                $flag |= re_flags_to_hs_flags($mod);
            }
            else {
                $flag |= $spec->{flag} if defined $spec->{flag};
            }

            push @expressions, $pat;
            push @flags,       $flag;

            push @ids, defined $spec->{id} ? $spec->{id} : $id;

            push @ext, $spec->{ext};
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

    if ( $self->{mode} eq "stream" ) {
        $self->{stream} = $self->{db}->open_stream();
    }

    return;
}

sub scan {
    my $self = shift;

    my $data = shift;

    my $flags = shift;
    $flags = defined $flags ? $flags : 0;

    if ( $self->{mode} eq "block" ) {
        return $self->{db}->scan( $data, $flags, $self->{scratch} );
    }
    elsif ( $self->{mode} eq "stream" ) {
        return $self->{stream}->scan( $data, $flags, $self->{scratch} );
    }
    elsif ( $self->{mode} eq "vectored" ) {
        return $self->{db}->scan_vector( $data, $flags, $self->{scratch} );
    }
    else {
        croak "unknown mode $self->{mode}";
    }
}

sub reset {
    my ( $self, $flags ) = @_;

    croak "reset only supported in stream mode"
      if $self->{mode} ne "stream";

    $flags = 0 if not defined $flags;

    return $self->{stream}->reset( $flags, $self->{scratch} );
}

1;
