# Octicka - Experiment Manager for Octave

Octicka is a simplified version of Opticka for **Octave**. The reason to make this fork is that Octave does not support many of MATLAB's `classdef` features that Opticka's OOP style depends on. The general idea is to move classes across from octicka, then strip out the features until they work. Not using the GUI should mean we can simplify some things, but we will have a major issue with stimuli that use dynamic properties with get and set methods, lets see how this can work. For `dynamicprops` we will have to use a struct and some classes that can find either the source (e.g. `size`) or the temporary (e.g. `sizeOut`) property used at runtime.

screenManager seems to work fine so far...
