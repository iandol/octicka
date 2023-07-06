function f = basicTraining()

	graphics_toolkit qt

	## Create figure and panel on it
	f = uifigure;
	## Create a button group
	gp = uibuttongroup (f, "Position", [ 0 0.5 1 1])
	## Create a buttons in the group
	b1 = uicontrol (gp, "style", "radiobutton", ...
					"string", "Choice 1", ...
					"Position", [ 10 150 200 50 ]);
	b2 = uicontrol (gp, "style", "radiobutton", ...
					"string", "Choice 2", ...
					"Position", [ 10 50 200 30 ]);
	## Create a button not in the group
	b3 = uicontrol (f, "style", "radiobutton", ...
					"string", "Not in the group", ...
					"Position", [ 10 50 200 50 ]);

	p = uipanel (f, "title", "Panel Title", "position", [0 0 .5 .5]);

	## add two buttons to the panel
	b1 = uicontrol ("parent", p, "string", "A Button", ...
					"position", [18 10 150 36]);
	b2 = uicontrol ("parent", p, "string", "Another Button", ...
					"position",[18 60 150 36]);

end
