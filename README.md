# Octicka - Experiment Manager for Octave

Octicka is a simplified version of Opticka for Octave. The reason to make this fork is that Octave does not support many `classdef` features that Opticka OOP style depends on. The general idea is to move classes across from opticka, then strip out the features until they work. Not using the GUI should mean we can simplify some things, but we will have a major issue with stimuli that use dynamic properties and get and set methods, lets see how this can work. 

screenManager seems to work fine so far...
