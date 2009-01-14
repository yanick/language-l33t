package Language::l33t::Operators;

use strict;
use warnings;

use Moose::Role;

use MooseX::Method::Signatures;
use Readonly;
use Carp;

requires qw/ _incr_op_ptr _incr_mem_ptr _incr_mem /;

Readonly my $NOP => 0;
Readonly my $WRT => 1;
Readonly my $RD  => 2;
Readonly my $IF  => 3;
Readonly my $EIF => 4;
Readonly my $FWD => 5;
Readonly my $BAK => 6;
Readonly my $INC => 7;
Readonly my $DEC => 8;
Readonly my $CON => 9;
Readonly my $END => 10;

my @op_codes;

$op_codes[$NOP] = \&_nop;
$op_codes[$WRT] = \&_wrt;
$op_codes[$RD]  = \&_rd;
$op_codes[$IF]  = \&_if;
$op_codes[$EIF] = \&_eif;
$op_codes[$FWD] = \&_fwd;
$op_codes[$BAK] = \&_bak;
$op_codes[$INC] = \&_inc;
$op_codes[$DEC] = \&_dec;
$op_codes[$CON] = \&_con;
$op_codes[$END] = \&_end;

sub opcode {
    my $index = $_[1];
    if ( $index > $#op_codes or $index < 0 ) {
        warn "j00 4r3 teh 5ux0r\n";
        $index = $NOP;
    }
    return $op_codes[ $index ]->( $_[0] );
}


sub _inc {
    my $self = shift;
    my $sign = shift || 1;
    $self->_incr_op_ptr;
    $self->_incr_mem( $sign * ( 1 + $self->memory_index( $self->op_ptr ) ) );
    $self->_incr_op_ptr;
    return 1;
}

sub _dec {
    return $_[0]->_inc( -1 );
}

sub _nop {
    $_[0]->_incr_op_ptr;
    return 1;
}

sub _end {
    return 0;
}


method _con {
    my $ip = join '.', map { 
                            my $x = $self->_get_current_mem; 
                            $self->_incr_mem_ptr;
                            $x || 0;
                           } 1..4;

    my $port = ( $self->_get_current_mem() || 0 ) << 8;
    $self->_incr_mem_ptr;
    {
        no warnings qw/ uninitialized /;
        $port += $self->_get_current_mem;
    }

    $self->_incr_mem_ptr( -5 );

    warn "trying to connect at $ip:$port\n" 
        if $self->debug;

    if ( "$ip:$port" eq '0.0.0.0:0' ) {
        $self->set_socket( undef );
    }
    else {
        if ( my $sock = IO::Socket::INET->new( "$ip:$port" ) ) {
            $self->set_socket( $sock );
        } 
        else {
            warn "h0s7 5uXz0r5! c4N'7 c0Nn3<7 101010101 l4m3R !!!\n";
        }
    }

    $self->_incr_op_ptr;
    return 1;
}


sub _fwd {
    my $self = shift;
    my $direction = shift || 1;
    $self->_incr_op_ptr;
    $self->_incr_mem_ptr( $direction * ( 1 + $self->_current_op )  );
    $self->_incr_op_ptr;

    return 1;
}

sub  _bak { return $_[0]->_fwd( -1 ); }

method _wrt { 
    if ( my $io = $self->socket || $self->stdout ) {
        no warnings qw/ uninitialized /;
        print {$io} chr $self->_get_current_mem;
    }
    else {
        print chr $self->_get_current_mem;
    }
    $self->_incr_op_ptr;

    return 1;
}

method _rd {
    my $chr;

    if ( my $io = $self->socket || $self->stdin ) {
        read $io, $chr, 1;
    }
    else {
        read STDIN, $chr, 1;
    }

    $self->_set_current_mem( ord $chr );
    $self->_incr_op_ptr;

    return 1;
}


method _if {
    if ( $self->_get_current_mem ) {
        $self->_nop;
    }
    else {
        my $nest_level = 0;
        my $max_iterations = $self->memory_size;

        SCAN:
        while (1) {
            $self->_incr_op_ptr;
            $max_iterations--;

            $nest_level++ and redo if $self->_current_op == $IF;

            if ( $self->_current_op == $EIF ) {
                if ( $nest_level ) {
                    $nest_level--;
                }
                else {
                    break SCAN;        
                }
            }

            croak "dud3, wh3r3's my EIF?" unless $max_iterations;
        }
    }

    return 1;
}

method _eif {
    if ( ! $self->_get_current_mem ) {
        $self->_nop;
    }
    else {
        $self->_incr_op_ptr( -1 ) until $self->_current_op == 3;
    };

    return 1;
}
1;
