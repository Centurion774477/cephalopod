#!/usr/bin/perl

use strict; use warnings;
use feature 'say';

require 'cepha.pl';

say '
Cephalopod CLI:
What would you like to do today?
1 -> Create a new scene
2 -> Add to a scene
3 -> Remove from a scene
4 -> Revert an action
5 -> Seal a scene
6 -> See documentation
Sprint:
7 -> Start a sprint
8 -> View tasks
9 -> Take/give
10 -> Take/abandon
';
say 'Provide the number and arguments for your function. Example: (1, newScene)';

chomp(my $gets = <STDIN>);

sub documentation {
    say 'documentation subroutine';
}

my %dispatch = {
    '1' => newScene(),
    '2' => give(),
    '3' => drop(),
    '4' => regret(),
    '5' => seal(),
    '6' => documentation(),
    '7' => sprint(),
    '8' => tasks(),
    '9' => takeGive(),
    '10' => takeAbandon()
};

my $dispatch = /%dispatch;
if (exists $dispatch{$gets}) {
    my @arguments = split(', ', $gets);
    if ($gets eq '9') { # the only function that requires two arguments
        $dispatch{$gets}->(@arguments[0], @arguments[1]);
    } else {
        $dispatch{$gets}->(@arguments[0]);
    }
    
} else {
    say 'invalid input'; redo;
}
