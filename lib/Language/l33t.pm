package Language::l33t;

use strict;
use warnings;
use Carp;

use MooseX::SemiAffordanceAccessor;
use Moose;

use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;
use MooseX::MakeImmutable;

use Readonly;
use IO::Socket::INET;

our $VERSION = '0.03';

subtype 'l33tByteSize' 
            => as 'Int' 
            => where { $_ > 10 }
            => message { "Byt3 s1z3 must be at l34st 11, n00b!" };

has debug => ( default => 0, is => 'rw' );
has code => ( is => 'rw' );

has byte_size => ( is => 'rw', isa => 'l33tByteSize', default => 256 );

has memory => ( 
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Int]',
    auto_deref => 1,
    provides => {
        set => 'memory_set',
        get => 'memory_index',
    },
    predicate => 'has_memory',
);

has memory_size => ( is => 'rw', default => 64 * 1024 );

has mem_ptr => ( is => 'rw' );
has op_ptr => ( is => 'rw' );
has stdout => ( is => 'rw', default => sub { return \*STDOUT;  } );
has stdin => ( is => 'rw' ); 
has 'socket' => ( is => 'rw' );

my @op_codes;

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

method initialize {
    # final zero for the initial memory
    my @memory = (  map ( { my $s = 0; 
                        $s += $& while /\d/g; 
                        $s % $self->byte_size 
                      } split ' ', $self->code ), 0 );

    if ( $self->memory_size < @memory ) {
        warn "F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!\n"; 
        return 0;
    }

    $self->set_op_ptr(0);
    $self->set_mem_ptr( $#memory );

    $self->{memory} = \@memory ;

    if( $self->debug ) {
        warn "compiled memory: ", join( ':', $self->memory ), "\n";
    }

    return 1;
}

method load ( Str $code ) {
    $self->set_code( $code );

    if( $self->debug ) {
        warn "code: $code\n";
    }

    return $self->initialize;
}

method run ( Int $nbr_iterations = -1 ) {
    unless ( $self->has_memory ) {
       carp 'L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!';
       return 0;
    }
  
    while ( $self->_iterate ) {
        $nbr_iterations-- if $nbr_iterations != -1;
        return 1 unless $nbr_iterations;
    }

    return 0;
}

method _iterate {
    my $op_id = $self->memory_index( $self->op_ptr ); 
 
    if ( $self->debug ) { 
        no warnings qw/ uninitialized /;
        warn "memory: ", join( ':', $self->memory ), "\n";
        warn "op_ptr: $self->op_ptr, ",
                "mem_ptr: $self->mem_ptr, ",
                "op: $op_id, ",
                "mem: ", $self->_get_current_mem, "\n";
    }

    warn "j00 4r3 teh 5ux0r\n" if $op_id > 10;

    if ( my $op = $op_codes[ $op_id ] ) {
        return $op_codes[ $op_id ]->( $self );
    }
    else {
        return $self->_nop;
    }
}

method _nop {
    $self->_incr_op_ptr;
    return 1;
}

method _end {
    return 0;
}

method _incr_op_ptr ( $increment = 1 ) {
    $self->set_op_ptr( $self->op_ptr + $increment );
}

method _incr_mem_ptr ( $increment = 1 ) {
    $self->set_mem_ptr( $self->mem_ptr + $increment );
}

method _incr_mem ( $increment ) {
    $self->memory_set( $self->mem_ptr => 
            ( $self->memory_index( $self->mem_ptr ) + $increment ) %
            $self->byte_size );
}

method _inc ( $sign = 1 ) {
    $self->_incr_op_ptr;
    $self->_incr_mem( $sign * ( 1 + $self->memory_index( $self->op_ptr ) ) );
    $self->_incr_op_ptr;
    return 1;
}

method _dec {
    return $self->_inc( -1 );
}

method _set_current_mem ( Int $value ) {
    return $self->memory_set( $self->mem_ptr => $value );
}

method _get_current_mem {
    return $self->memory_index( $self->mem_ptr );
}

method _current_op {
    return $self->memory_index( $self->op_ptr ) || 0;
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

method _fwd( $direction = 1 ) {
    $self->_incr_op_ptr;
    $self->_incr_mem_ptr( $direction * ( 1 + $self->_current_op )  );
    $self->_incr_op_ptr;

    return 1;
}

method  _bak { $self->_fwd( -1 ); return 1; }

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

MooseX::MakeImmutable->lock_down;

1; # End of Language::l33t

__END__

=head1 NAME

Language::l33t - a l33t interpreter

=head1 SYNOPSIS

    use Language::l33t;

    my $interpreter = Language::l33t->new;
    $interpreter->load( 'Ph34r my l33t sk1llz' );
    $interpreter->run;

=head1 DESCRIPTION

Language::l33t is a Perl interpreter of the l33t language created by
Stephen McGreal and Alex Mole. For the specifications of l33t, refer
to the REFERENCE section.

=head1 METHODS

=head2 new( \%options )

Creates a new interpreter. The options that can be passed to the function are:

=over

=item debug => $flag

If $flag is set to true, the interpreter will print debugging information
as it does its thing.

=item stdin => $io

=item stdout => $io

Ties the stdin/stdout of the interpreter to the given object. 

E.g.:

    my $output;
    open my $fh_output, '>', \$output;

    my $l33t = Language::l33t->new({ stdout => $fh_output });

    $l33t->load( $code );
    $l33t->run;

    print "l33t output: $output";

=item memory_size => $bytes

The size of the block of memory used by the interpreter. By default set to
64K (as the specs recomment).

=item byte_size => $size

The size of a byte in the memory used by the interpreter. Defaults to
256 (so a memory byte can hold a value going from 0 to 255).



=back

=head2 load( $l33tcode )

Loads and "compiles" the string $l33tcode. If one program was already loaded,
it is clobbered by the newcomer. Returns 1 upon success, 0 if the loading
failed.

=head2 run( [ $nbr_iterations ] )

Runs the loaded program. If $nbr_iterations is given, interupts the program
after this number of iterations even if it hasn't terminated. Returns 0 in
case the program terminated by evaluating an END, 1 if it finished by reaching
$nbr_iterations.

=head2 initialize

Initializes, or reinitializes the interpreter to its initial setting. Code is
recompiled, and pointers reset to their initial values. Implicitly called when
new code is load()ed. 

Returns 1 upon success, 0 if something went wrong.

E.g.

    my $l33t = Language::l33t->new();
    $l33t->load( $code );
    $l33t->run;

    # to run the same code a second time
    $l33t->initialize;
    $l33t->run;


=head2 memory

Returns the memory of the interpreter in its current state as an array.

=head1 DIAGNOSTICS

=over

=item F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!

You tried to load a program that is too big to fit in 
the memory. Note that at compile time, one byte is reserved
for the memory buffer, so the program's size must be less than
the memory size minus one byte.

=item Byt3 s1z3 must be at l34st 11, n00b!

The I<byte_size> argument of I<new()> was less than 11. 
The byte size of an interpreter must be at least 11 (to
accomodate for the opcodes).

=item L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!

run() called before any program was load()ed.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-l33t at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Language::l33t>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Language::l33t

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Language::l33t>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Language::l33t>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Language::l33t>

=item * Search CPAN

L<http://search.cpan.org/dist/Language::l33t>

=back

=head1 REFERENCES

Stephen McGreal's l33t page: http://electrod.ifreepages.com/l33t.htm

Wikipedia article on l33t: http://en.wikipedia.org/wiki/L33t_programming_language

=head1 AUTHOR

Yanick Champoux, C<< <yanick at cpan.org> >>

=head1 THANKS 

It goes without saying, special thanks go 
to Stephen McGreal and Alex Mole for inventing l33t. 
They are teh rOxX0rs.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Yanick Champoux, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

