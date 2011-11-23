#!/usr/bin/perl 

use MooseX::Declare;

class Foo {
    my $i;

    sub bar { ++$i; } 
}

package main;

my $foo = Foo->new;
print $foo->bar;


