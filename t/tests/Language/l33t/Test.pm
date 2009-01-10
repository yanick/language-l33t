package Language::l33t::Test;

use strict;
use warnings;

use base 'Test::Class::Runnable';
use Test::More;

use Language::l33t;

sub inc :Test(1) {
    my $l33t = Language::l33t->new;

    $l33t->load( '7 75 55' );
    $l33t->run;
    is( join( ':', $l33t->memory ), '7:12:10:13', 'INC' );
}

sub dec :Test(1) {
    my $l33t = Language::l33t->new;

    $l33t->load( '8 75 55' );
    $l33t->run;
    is( join( ':', $l33t->memory ), '8:12:10:243', 'DEC' );
}

sub if_without_eif :Test(1) {
    my $l33t = Language::l33t->new;

    $l33t->load( '3 5o5' );
    eval { $l33t->run; };

    like $@ => qr/dud3, wh3r3's my EIF?/, 'IF without EIF';
}

sub opcode_over_10 :Test(1) {
    my $l33t = Language::l33t->new;
    local *STDERR;

    my $errors;
    open STDERR, '>', \$errors;

    $l33t->load( '777 55' );
    $l33t->run;

    is $errors, "j00 4r3 teh 5ux0r\n", 'error if opCode > 10';
}

sub invalid_socket :Test(1) {
    my $l33t = Language::l33t->new;
    local *STDERR;
    my $errors;
    open STDERR, '>', \$errors;

    $l33t->load( '6 5 9 55 999999999999991 0 0 1 999999998 999999998' );
    $l33t->run;

    is $errors, "h0s7 5uXz0r5! c4N'7 c0Nn3<7 101010101 l4m3R !!!\n",
        'error if connect to invalid socket';
}

sub running_without_loading :Test(1) {
    local *STDERR;

    my $errors;
    open STDERR, '>', \$errors;

    # try to run without load first? 
    my $l33t = Language::l33t->new();
    $l33t->run;

    like $errors => qr/^L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!/,
        'run()ning before load()ing a program';
}

sub memory :Test(6) {

    {
        local *STDERR;
        my $errors;
        open STDERR, '+>', \$errors;

        # test the error message if the program is bigger than 
        # the memory size
        my $l33t = Language::l33t->new({ memory_size => 10 });

        is $l33t->load( join ' ', 1..9 ) => 1, 'program within the memory size';
        is $errors => undef, 'program within the memory size';

        is $l33t->load( join ' ', 1..10 ) => 0, 'program outside the memory size';
        is $errors => "F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!\n", 'program outside the memory size';
        }

    # test if the byte size is respected, by default

    my $output;
    open my $fh_output, '>', \$output;
    my $l33t = Language::l33t->new({ stdout => $fh_output });

    $l33t->load( '7 '.( '9'x( 256/9 ) ).' 7 7 1 5o5' );
    $l33t->run;
    my $expected = ( 9*int( 256/9 ) + 9 ) % 256;
    is ord($output) => $expected, 'default byte size';

    # test if the byte size is respected, if different than default

    close $fh_output;
    $output = q{};
    open $fh_output, '>', \$output;
    $l33t = Language::l33t->new({ stdout => $fh_output,
                            byte_size => 11 });

    $l33t->load( '7 9 7 1 1 5o5' );
    $l33t->run;

    is ord( $output ), 1, 'byte size';
}

sub sample :Test(1) {

my $output;
open my $fh_output, '>', \$output;
my $l33t = Language::l33t->new( stdout => $fh_output );

$l33t->load( <<'END_CODE' );
    Gr34t l33tN3$$? 
    M3h...
    iT 41n't s0 7rIckY.

    l33t sP33k is U8er keWl 4nD eA5y wehn u 7hink 1t tHr0uGh.
    1f u w4nn4be UB3R-l33t u d3f1n1t3lY w4nt in 0n a b4d4sS h4xX0r1ng s1tE!!! ;p
    w4r3Z c0ll3cT10n2 r 7eh l3Et3r!

    Qu4k3 cL4nS r 7eh bE5t tH1ng 1n teh 3nTIr3 w0rlD!!!
    g4m3s wh3r3 u g3t to 5h00t ppl r 70tAl1_y w1cK1d!!
    I'M teh fr4GM4stEr aN I'lL t0t41_1Ly wIpE teh phr34k1ng fL00r ***j3d1
    5tYlE*** wItH y0uR h1dE!!!! L0L0L0L!
    t3lEphR4gG1nG l4m3rs wit mY m8tes r34lLy k1kK$ A$$

    l33t hAxX0r$ CrE4t3 u8er- k3wL 5tUff lIkE n34t pR0gR4mm1nG lAnguidGe$...
    s0m3tIm3$ teh l4nGu4gES l00k jUst l1k3 rE41_ 0neS 7o mAkE ppl Th1nk
    th3y'r3 ju$t n0rMal lEE7 5pEEk but th3y're 5ecRetLy c0dE!!!!
    n080DY unDer5tAnD$ l33t SpEaK 4p4rT fr0m j3d1!!!!!
    50mE kId 0n A me$$4gEb04rD m1ghT 8E a r0xX0r1nG hAxX0r wH0 w4nT2 t0 bR34k
    5tuFf, 0r mAyb3 ju5t sh0w 7eh wAy5 l33t ppl cAn 8E m0re lIkE y0d4!!! hE i5 teh
    u8ER!!!!
    1t m1ght 8E 5omE v1rus 0r a Pl4ySt4tI0n ch34t c0dE.
    1t 3v3n MiTe jUs7 s4y "H3LL0 W0RLD!!!" u ju5t cAn'T gu3s5.
    tH3r3's n3v3r anY p0iNt l00KiNg sC3pT1c4l c0s th4t, be1_1Ev3 iT 0r n0t, 1s
    whAt th1s 1s!!!!!

    5uxX0r5!!!L0L0L0L0L!!!!!!!
END_CODE

$l33t->run;

is $output => 'H3LL0 W0RLD!!!', 'sample 1';

}

1;
