#!/usr/bin/perl

use strict; use warnings;
use feature 'say';
use feature 'signatures';
use TOML::Tiny;
use Path::Tiny;

my $configFile = path("cepha_conf.toml");
my $context = (
    scene => undef,
    children => []
);

# see cepha.txt for documentation

# creates a new scene and adds to the context stack-- 
# argue sceneName
sub newScene {
    my $sceneName = shift;
    # eventually I'll rig up toml or some other config to store data but for now its shallow
    $context->{scene} = $sceneName;
    $configFile->spew(to_toml($context));
}

# give/child
# argue childName
sub give {
    unless (defined $context->{scene}) {
        die "contextError: no context set, cannot give to child";
    }
    my $childName = shift;
    push @{$context->{children}}, $childName;
}

# drop/kick
# argue childName
sub drop {
    my $childName = shift;
    die "contextError: no context set, cannot drop child" unless (defined $context->{scene}) 
    @{$context->{children}} = grep { $_ ne $childName } @{$context->{children}};
}

# clears the context stack
# no arguments because cepha has mono-context
sub seal {
    die "contextError: no context set" unless defined $context->{scene};
    $configFile->spew(to_toml($context));
    $context->{scene} = undef;
    $context->{children} = [];
}

# I'm not gonna add any of the other commands yet

my $input = join(' ', @ARGV);


# cepha new sceneName
if ($input =~ /(cepha)(\s+)(new)(\s+)([a-zA-Z_]+)/) {
    newScene($5);
}
# cepha sceneName.give(childName) || cepha sceneName.child(childName)
elsif ($input =~ /(cepha)(\s+)([a-zA-Z_]+)\.(give|child)\(([a-zA-Z_]+)\)/) {
    give($5);
}
# cepha sceneName.drop(childName) || cepha sceneName.kick(childName)
elsif ($input =~ /(cepha)(\s+)([a-zA-Z_]+)\.(drop|kick)\(([a-zA-Z_]+)\)/) {
    drop($5);
}
# cepha seal
elsif ($input =~ /(cepha)(\s+)(seal)/) {
    seal();
}
# cepha tasks sceneName
elsif ($input =~ /(cepha)(\s+)(tasks)(\s+)([a-zA-Z_]+)/) {
    say "matched a tasks call"
}
# cepha take(sceneName)->give(childName)
elsif ($input =~ /(cepha)(\s+)(take)\(([a-zA-Z_]+)\)->(give)\(([a-zA-Z_]+)\)/) {
    say "matched a take -> give call"
}
# cepha take(sceneName)->abandon
elsif ($input =~ /(cepha)(\s+)(take)\(([a-zA-Z_]+)\)->abandon/) {
    say "matched a take -> abandon call"
}
else {
    die "argumentError:" . $input . " is not a recognized Cephalopod command"
}