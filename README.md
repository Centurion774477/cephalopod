# cephalopod

You open up Blender and say: "Bedroom. Got it --I need a bed, a nightstand, etc." 
--what you don't say is "I'm perfectly content with spilling assets from my bedroom into my living room!".
Cephalopod will inherently prevent that pourover:

Cephalopod is an opinionated version control system for 3D artists.
I took an immutable scene-based approach to version control: assets are dropped into scenes and then the scene is sealed.

Scenes are the best way to handle a system of this type, because its exactly how you're thinking when you are designing a scene.

I created Cephalopod because other VCS's are too general-purpose --Git has too many commands, and still is lackluster in many areas.
Therefore, every command serves a specific purpose to help 3D artists.

Just like Git, and many other systems, Cephalopod is designed to run in the terminal.

The very first cephalopod command you will likely use is:
```
cepha new sceneName
# example:
cepha new kitchen
```
This will create a new scene and add it to your context --no need to refer to it any more!
To add assets to the scene:
```
cepha sceneName.give(asset)
# you could also use the child alias:
cepha sceneName.child(asset)
# example:
cepha kitchen.child(toaster.obj)
```
While Cephalopod does use immutable scenes, they aren't immutable until closed.
Therefore if you made a mistake while adding, you can drop the asset:
```
cepha sceneName.drop(asset)
# or the kick alias:
cepha sceneName.kick(asset)
# example:
cepha kitchen.drop(toaster.obj)
```
Once you are done adding or removing from a scene, you seal the scene to make it immutable:
```
cepha seal
```
Cephalopod does not require any more specification --it purposely has a one scene context; but that also means you cannot have multiple scenes open at once.


If you want to take one of your sealed scenes and copy it, Cephalopod offers an idiomatic route:
The first step is to type
```
cepha tasks sceneName
# example:
cepha tasks kitchen
```
This will give you a key-value pair of every asset and its status for this instance 'sprint'
example:
```
toaster.obj -> neutral
```
There are three possible statuses:
* replaced
* neutral
* abandoned

Neutral will be the default status; it will take that object and copy it to your new instance.
Replacing an object would be if you have a newer toaster model, for example; in order to replace:
```
cepha take(toaster.obj)->give(toasterOven.obj)
```
In order to abandon:
```
cepha take(toaster.obj)->abandon
```
These two commands could very well be enough to complete your sprint. If so, you can seal right now.
But if you need to add entirely new objects, the give/child method is right there, waiting for you.

