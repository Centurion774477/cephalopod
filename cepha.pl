#!/usr/bin/perl

use strict; use warnings;
use feature 'say';
use feature 'signatures';
use TOML::Tiny;
use Path::Tiny;

my $configFile = path("cepha_conf.toml");
my $context = {
    scene => undef,
    children => []
    time_stamp => undef
};
# instead of a global boolean I'll check for sceneName's definition (undef or not)
my $plannedScene = {
    sceneName => undef,
    reoccurences => [], # populated by canonObjects later on; the assets from the original scene
    newObjects => [], # any new objects; added via a normal give/child command. See *
    time_stamp => undef
};

# * it's a normal give/child command for the user, but under the hood it's different.

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
    push @{$context->{children}}, {name => $childName, status => "neutral"};
}

# drop/kick
# argue childName
sub drop {
    my $childName = shift;
    die "contextError: no context set, cannot drop child" unless (defined $context->{scene}); 
    @{$context->{children}} = grep { $_->{name} ne $childName } @{$context->{children}};
}

# clears the context stack
# no arguments because cepha has mono-context
sub seal {
    die "contextError: cannot seal because no context is set" unless defined $context->{scene};
    $context->{time_stamp} = time();
    $configFile->spew(to_toml($context));
    $context->{scene} = undef;
    $context->{children} = [];
}

# just like the normal give, but meant to contribute to a sprint instead of a normal scene.
# argue objectName
sub sprintGive {
    my $objectName = shift;
    unless ($objectName =~ /([a-zA-Z0-9_]+)\.([a-z]+)/) {
        die 'invalid asset. Please declare a file extension, such as .obj'
    }
    push @{$plannedScene->{newObjects}}, $objectName
}

# argue sceneName
sub tasks {
    die 'sprintError: define a sprint' unless defined $plannedScene->{sceneName};

    my $tasksFor = shift;
    die unless defined $context->{scene} && $context->{scene} eq $tasksFor;
    my $data = from_toml($config_file->slurp);
    my @canonObjects = @{$data->children}
    # canonObjects represents every object from the original scene; they must be represented
    for my $child (@canonObjects) {
        # toaster.obj -> neutral
        say $child->{name} . "->" . $child->{status}
        push @{$plannedScene->{reoccurences}}, $child 
            unless grep {$_ eq $child } {$plannedScene->{reoccurences}};
        # I'm trying to check for duplicates
    }
    # this implicitly pulls $tasksFor into the context, so we don't need to keep referring to it in take-give/take-abandon
    unless (grep { $_ eq $tasksFor } @{$context->{children->{name}}}) {
        die "containmentBreach:" . $tasksFor . "was not sealed";
    }
    $context->{scene} = $tasksFor; 
}

# argue oldAsset, newAsset, and @canonObjects
sub takeGive {
    my ($oldAsset, $newAsset) = @_;
    unless (defined $context->{scene}) {
        die "contextError: no context set. Please call tasks for this scene";
    }
    my $sceneName = $context->{scene}
    die 'invalid argument for oldAsset; nonexistent' unless grep { $_ eq $oldAsset} {@children->children}
    die 'sprintError: define a sprint' unless defined $plannedScene->{sceneName}
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
}

# argue oldAsset
sub takeAbandon {
    my $oldAsset = shift;
    my $ABANDON = 'abandon';
    if ($context->{scene} eq undef) {
        die "contextError: no context set. Please call tasks for this scene";
    }
    say "take abandon";
    for my $child (@{$plannedScene->{reoccurences}}) {
        if ($child->{name} eq $oldAsset) {
            $child->{status} = $ABANDON;
            $found = 1;
            last;
        }
       
    }
}

# required for every other sprint command (tasks, takeGive, takeAbandon)
# argue instanceName
sub sprint {
    my $instanceName = shift;
    die 'containmentBreach: seal your current scene before proceeding' if defined $context->{scene};
    ($plannedScene->{sceneName}, $plannedScene->{time_stamp}) = ($instanceName, time());
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
else {
    die "argumentError:" . $input . " is not a recognized Cephalopod command";
}