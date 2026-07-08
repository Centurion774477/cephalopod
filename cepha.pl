#!/usr/bin/perl

use strict; use warnings;
use feature 'say';
use feature 'signatures';
use TOML::Tiny;
use Path::Tiny;
use JSON::Tiny;

my $configFile = path("cepha_conf.jsonl");
my $context = {
    scene => undef,
    children => [],
    time_stamp => undef
};
# instead of a global boolean I'll check for sceneName's definition (undef or not)
my $plannedScene = {
    sceneName => undef,
    reoccurences => [], # populated by canonObjects later on; the assets from the original scene
    newObjects => [], # any new objects; added via the give/child command
    time_stamp => undef
};

my $lastAction = {type => undef, removedObject => undef}; # example: type => kick, removedObject = kickedObject
# creates a new scene and adds to the context stack--
# argue sceneName
sub newScene {
    my $sceneName = shift;
    $context->{scene} = $sceneName;
    say 'Created new scene' . $sceneName;
}

# argue childName
sub give {
    unless (defined $context->{scene}) {
        die "contextError: no context set, cannot give to child";
    }
    my $childName = shift;
    push @{$context->{children}}, {name => $childName, status => "neutral"};
    say 'Got it. Placed' . $childName . 'into' . $context->{scene};
}

# argue childName
sub drop {
    my $childName = shift;
    die "contextError: no context set, cannot drop child. Initiate a scene" unless (defined $context->{scene}); 
    @{$context->{children}} = grep { $_->{name} ne $childName } @{$context->{children}};
    # filter out all the names that aren't child name
    $lastAction->{type} = 'drop';
    $lastAction->{comment} = $childName;
    say "Done! Dropped" . $childName . 'From' . $context->{scene};
}

# the main use case is reverting a drop/kick
sub regret {
    unless (defined $lastAction->{type}) {
        die 'Sorry, your last action is not reversible.';
    }
    unless (defined $context->{scene}) {
        die 'Sadly, your changes were finalized through the seal command; unable to reverse.';
    }
    die 'sorry, only drop/kick reversion is supported right now' unless $lastAction->{type} eq 'drop';
    push @{$context->{children}}, $lastAction->{removedObject};
    say "Fixed! $lastAction->{removedObject} is back in $context->{scene}";
}

# clears the context stack
# no arguments because cepha has mono-context
sub seal {
    die "contextError: cannot seal because no context is set" unless defined $context->{scene};
    $context->{time_stamp} = time();
    $configFile->append(encode_json($context) . "\n");
    $context->{scene} = undef;
    $context->{children} = [];
    
}

# just like the normal give, but meant to contribute to a sprint instead of a normal scene.
# argue objectName
sub sprintGive {
    my $objectName = shift;
    if (defined $context->{scene}) {
        die 'Unexpected Error --seal your current scene';
    }
    unless (defined $plannedScene->{sceneName}) {
        die 'You are not currently in a sprint; start one with cepha sprint instanceName';
    }
    # check for a file extension in the given asset
    unless ($objectName =~ /([a-zA-Z0-9_]+)\.([a-z]+)/) {
        die 'invalid asset. Please declare a file extension, such as .obj';
    }
    push @{$plannedScene->{newObjects}}, $objectName;
    say 'Done! Stashed' . $objectName . 'in' . $plannedScene->{sceneName}
}

# argue sceneName --no longer implictly starts a sprint; just double checks
sub tasks {
    my $sceneName = shift;
    die 'sprintError: define a sprint' unless defined $plannedScene->{sceneName};
    unless ($sceneName eq $plannedScene->{sceneName}) {
        warn 'You have a sprint defined, but you argued' . $sceneName . 'for tasks instead of' . $plannedScene->{sceneName}
            . 'but dont worry --Cephalopod will fix this. Keep on keeping on!';
        $sceneName = $plannedScene->{sceneName};
    }
    # I don't see why I should fail there because we already know what it should be. Therefore autocorrect it and keep on moving
    my @scenes = map {decode_json($_)}
        $configFile->lines({chomp => 1});
    my ($foundScene) = grep {$_->{scene} eq $sceneName} @scenes;
    die 'Error: failed to find' . $sceneName . 'in your scene history' unless $foundScene;
    for my $child (@{$foundScene->{children}}) {
        # print each object and its status; toaster.obj -> neutral
        say $child->{name} . "->" . $child->{status};
        push @{$plannedScene->{reoccurences}}, $child
            unless grep {$_ eq $child } {$plannedScene->{reoccurences}};
        # check for duplicates; push child into reoccurences unless its already in there
    }
}

# argue oldAsset, newAsset, and @canonObjects
sub takeGive {
    my ($oldAsset, $newAsset) = @_;
    unless (defined $context->{scene}) {
        die "contextError: no context set. Please call tasks for this scene";
    }
    my $sceneName = $context->{scene};
    die 'invalid argument for oldAsset; nonexistent' unless grep { $_ eq $oldAsset} {@{$context}->children};
    die 'sprintError: define a sprint' unless defined $plannedScene->{sceneName};
    # instead of replacing neutral with abandon, 
    # I'm replacing neutral with the file that is replacing it to save space
    my $found = 0;
    for my $child (@{$plannedScene->{reoccurences}}) {
        if ($child->{name} eq $oldAsset) {
           $child->{status} = $newAsset;
            $found = 1;
            last;
        }
    }
    say 'Done Deal! In with the new:' . $newAsset . '--and out with the old.';
}

# argue oldAsset
sub takeAbandon {
    my $oldAsset = shift;
    my $ABANDON = 'abandon';
    if ($context->{scene} eq undef) {
        die "contextError: no context set. Please call tasks for this scene";
    }
    say "take abandon";
    my $found = 0;
    for my $child (@{$plannedScene->{reoccurences}}) {
        if ($child->{name} eq $oldAsset) {
            $child->{status} = $ABANDON;
            $found = 1;
            last;
        }
    }
    say 'Done! Forgetting' . $oldAsset
}

# required for every other sprint command (tasks, takeGive, takeAbandon)
# argue instanceName
sub sprint {
    my $instanceName = shift;
    die 'containmentBreach: seal your current scene before proceeding' if defined $context->{scene};
    ($plannedScene->{sceneName}, $plannedScene->{time_stamp}) = ($instanceName, time());
    say 'You are now in a sprint for the scene:' . $instanceName;
}


my $input = join(' ', @ARGV);
# you know the regex is bad when your first argument is the fifth capture group
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
elsif ($input =~ /(cepha)(\s+)(sprint)(\s+)([a-zA-Z_]+)/) {
    sprint($5);
}
# cepha tasks sceneName
elsif ($input =~ /(cepha)(\s+)(tasks)(\s+)([a-zA-Z_]+)/) {
    tasks($5);
}
# cepha take(sceneName)->give(childName)
elsif ($input =~ /(cepha)(\s+)(take)\(([a-zA-Z_]+)\)->(give)\(([a-zA-Z_]+)\)/) {
    takeGive($4, $6);
}
# cepha take(sceneName)->abandon
elsif ($input =~ /(cepha)(\s+)(take)\(([a-zA-Z_]+)\)->abandon/) {
    takeAbandon($4);
}
elsif ($input =~ /(cepha)(\s+)(regret)/) {
    regret();
}
else {
    die "argumentError:" . $input . " is not a recognized Cephalopod command";
}