# Octicka - Experiment Manager for Octave

Octicka is a simplified version of the [Opticka experiment manager](https://iandol.github.io/opticka/) for **[Octave](https://octave.org)**. The reason to make this fork is that Octave does **not** support some of MATLAB's `classdef` features that Opticka's OOP style depends on. The general idea is to move classes across from octicka, replace  the features until they work. Not using the GUI should mean we can simplify some things. This should still work with MATLAB of course. 

The major issue was with the stimulus classes that depend on dynamic properties with get and set methods. For `dynamicprops` the solution was to use a regular `struct` (`stim.dp`) and some modifications using `subsref` & `subsasgn` so that they can find either the source (e.g. `size`) or the temporary (e.g. `sizeOut`) property used at runtime (and run a pseudo get/set method).

Most core classes are working, and we are currently using octicka with the Raspberry Pi 4 to run touchscreen based experiments (try the `TouchTraining` tool, which uses 20 steps to refine touch behaviour). The classes are easy-to-use compared to plain PTB:

```matlab
s = screenManager; % instantiate a screen manager object
s.distance = 65; % distance of the subject in cm
s.blend = true; % turn on OpenGL blending

ms = movieStimulus; % instatiate a movie stimulus object
ms.size = 14; % rescale it to 14° visual angle
ms.angle = 45; % rotate by 45°

ts = touchManager; % instantiate a touch manager object
ts.isDummy = true; % no need for a real touch screen, use mouse as dummy touch event
ts.window.radius = 8; % 8° radius of the touch window
ts.window.init = 5; % subject must touch within 5 seconds

open(s); % open the screen
setup(ms, s) % we link the movie stimulus to the screen object
setup(ts, s); % link the touch and screen managers

isTouch = false;
flip(s);
WaitSecs(1);
while ~isTouch
	draw(ms); % draw our movie frame
	animate(ms); animate to prepare the next frame
	[isTouch] = isHold(ts);
	flip(s)
end

drawtextNow(s, 'Finished!');
WaitSecs(1);
reset(ms); reset(ts);
close(s);
```



