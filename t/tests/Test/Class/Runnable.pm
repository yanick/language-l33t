package Test::Class::Runnable;

use strict;
use warnings;

BEGIN { use Test::Class };

use base 'Test::Class';

INIT { Test::Class->runtests };

1;
