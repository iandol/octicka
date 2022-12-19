% ========================================================================
%> @brief single disc stimulus, inherits from baseStimulus
%> SPOTSTIMULUS single spot stimulus, inherits from baseStimulus
%>   The current properties are:
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef spotStimulus < baseStimulus
	
	properties %--------------------PUBLIC PROPERTIES----------%
		%> type can be "simple" or "flash"
		type					= 'simple'
		%> colour for flash, empty to inherit from screen background with 0 alpha
		flashColour		= []
		%> time to flash on and off in seconds
		flashTime			= [0.25 0.25]
		%> is the ON flash the first flash we see?
		flashOn				= true
		%> contrast scales from foreground to screen background colour
		contrast			= 1
	end
	
	properties (SetAccess = protected, GetAccess = public)
		%> stimulus family
		family				= 'spot'
	end
	
	properties (SetAccess = private, GetAccess = public, Hidden = true)
		typeList			= {'simple','flash'}
	end
	
	properties (Dependent = true, SetAccess = private, GetAccess = private)
		%> a dependant property to track when to switch from ON to OFF of
		%flash.
		flashSwitch
	end
	
	properties (SetAccess = private, GetAccess = private)
		%> current flash state
		flashState
		%> internal counter
		flashCounter			= 1
		%> the OFF colour of the flash, usually this is set to the screen background
		flashBG						= [0.5 0.5 0.5]
		%> ON flash colour, reset on setup
		flashFG						= [1 1 1]
		currentColour			= [1 1 1]
		colourOutTemp			= [1 1 1]
		flashColourOutTemp = [1 1 1]
		stopLoop					= false
		allowedProperties = {'type','flashTime','flashOn','flashColour','contrast'}
		ignoreProperties	= {'flashSwitch'};
	end
	
	%=======================================================================
	methods %------------------PUBLIC METHODS
		%=======================================================================
		
		% ===================================================================
		%> @brief Class constructor
		%>
		%> More detailed description of what the constructor does.
		%>
		%> @param args are passed as a structure of properties which is
		%> parsed.
		%> @return instance of the class.
		% ===================================================================
		function me = spotStimulus(varargin)
			args = octickaCore.addDefaults(varargin,...
				struct('name','Spot','colour',[1 1 0 1]));
			me=me@baseStimulus(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);
			
			me.isRect = false; %uses a rect for drawing?

			me.ignoreProperties = [ me.ignorePropertiesBase me.ignoreProperties ];
		end
		
		% ===================================================================
		%> @brief Setup an structure for runExperiment
		%>
		%> @param sM handle to the current screenManager object
		% ===================================================================
		function setup(me,sM)
			
			reset(me);
			me.inSetup = true;
			if isempty(me.isVisible); me.show; end
			
			reset(me);
			me.inSetup = true; me.isSetup = false;
			if isempty(me.isVisible); me.show; end
			
			me.sM = sM;
			if ~sM.isOpen; error('Screen needs to be Open!'); end
			me.ppd=sM.ppd;
			me.screenVals = sM.screenVals;
			me.texture = []; %we need to reset this
			me.dp = struct;
			fn = fieldnames(me);
			for j=1:length(fn)
				if ~ismember(fn{j}, me.ignoreProperties)
					prop = [fn{j} 'Out'];
					p = addProperty(me, prop);
					v = me.setOut(p, me.(fn{j})); % our pseudo set method
					me.dp.(p) = v; %copy our property value to our tempory copy
				end
			end
			
			addRuntimeProperties(me);
			
			if me.doFlash
				if ~isempty(me.dp.flashColourOut)
					me.flashBG = [me.dp.flashColourOut(1:3) me.dp.alphaOut];
				else
					me.flashBG = [me.sM.backgroundColour(1:3) 0]; %make sure alpha is 0
				end
				setupFlash(me);
			end
			
			me.inSetup = false; me.isSetup = true;
			
			computeColour(me);
			computePosition(me);
			if me.doAnimator;setup(me.animator, me);end
		end
		
		% ===================================================================
		%> @brief Update a structure for runExperiment
		%>
		%> @param
		%> @return
		% ===================================================================
		function update(me)
			resetTicks(me);
			me.colourOutTemp = [];
			me.flashColourOutTemp = [];
			me.stopLoop = false;
			me.inSetup = false;
			computePosition(me);
			setAnimationDelta(me);
			if me.doFlash; me.setupFlash; end
		end
		
		% ===================================================================
		%> @brief Draw an structure for runExperiment
		%>
		%> @param sM runExperiment object for reference
		%> @return stimulus structure.
		% ===================================================================
		function draw(me)
			if me.isVisible && me.tick >= me.delayTicks && me.tick < me.offTicks
				if me.doFlash == false
					Screen('gluDisk',me.sM.win,me.dp.colourOut,me.xFinal,me.yFinal,me.dp.sizeOut/2);
				else
					Screen('gluDisk',me.sM.win,me.currentColour,me.xFinal,me.yFinal,me.dp.sizeOut/2);
				end
			end
			me.tick = me.tick + 1;
		end
		
		% ===================================================================
		%> @brief Animate an structure for runExperiment
		%>
		%> @param sM runExperiment object for reference
		%> @return stimulus structure.
		% ===================================================================
		function animate(me)
			if me.isVisible && me.tick >= me.delayTicks
				if me.mouseOverride
					getMousePosition(me);
					if me.mouseValid
						me.xFinal = me.mouseX;
						me.yFinal = me.mouseY;
					end
				end
				if me.doMotion == true
					me.xFinal = me.xFinal + me.dX_;
					me.yFinal = me.yFinal + me.dY_;
				end
				if me.doFlash == true
					if me.flashCounter <= me.flashSwitch
						me.flashCounter=me.flashCounter+1;
					else
						me.flashCounter = 1;
						me.flashState = ~me.flashState;
						if me.flashState == true
							me.currentColour = me.flashFG;
						else
							me.currentColour = me.flashBG;
						end
					end
				end
			end
		end
		
		% ===================================================================
		%> @brief Reset an structure for runExperiment
		%>
		%> @param sM runExperiment object for reference
		%> @return stimulus structure.
		% ===================================================================
		function reset(me)
			resetTicks(me);
			me.texture=[];
			removeTmpProperties(me);
			me.stopLoop = false;
			me.inSetup = false; me.isSetup = false;
			me.colourOutTemp = [];
			me.flashColourOutTemp = [];
			me.flashFG = [];
			me.flashBG = [];
			me.flashCounter = [];
		end
		
		% ===================================================================
		%> @brief flashSwitch Get method
		%>
		% ===================================================================
		function flashSwitch = get.flashSwitch(me)
			if me.flashState
				flashSwitch = round(me.dp.flashTimeOut(1) / me.sM.screenVals.ifi);
			else
				flashSwitch = round(me.dp.flashTimeOut(2) / me.sM.screenVals.ifi);
			end
		end
		
	end %---END PUBLIC METHODS---%
	
	%=======================================================================
	methods ( Hidden = true ) %-------HIDDEN METHODS-----%
	%=======================================================================
		
		% ===================================================================
		%> @brief our fake set methods, hooks into dynamicprops subsasgn
		%>
		% ===================================================================
		function v = setOut(me, S, v)
			if ischar(S)
				prop = S; 
			elseif isstruct(S) && strcmp(S(end).type, '.') && isfield(S,'subs')
				prop = S(end).subs;
			else
				return;
			end
			switch prop
				case 'sizeOut'
					v = v * me.ppd;
					if isProperty(me,'discSize') && ~isempty(me.discSize) && ~isempty(me.texture)
						me.scale = v / me.discSize;
						me.postSet = @setRect(me);
					end
				case {'xPositionOut' 'yPositionOut'}
					v = v * me.ppd;
				case {'colourOut'}
					me.isInSetColour = true;
					if length(v)==4 
						alpha = v(4);
					elseif isProperty(me,'alphaOut')
						alpha = me.dp.alphaOut;
					else
						alpha = me.alpha;
					end
					switch length(v)
						case 4
							if isProperty(me,'alphaOut')
								me.dp.alphaOut = alpha;
							else
								me.alpha = alpha;
							end
						case 3
							v = [v(1:3) alpha];
						case 1
							v = [v v v alpha];
					end
					if isempty(me.colourOutTemp); me.colourOutTemp = v;end
					contrast = getP(me,'contrast');
					if ~me.inSetup && ~me.stopLoop && contrast < 1
						me.postSet = @computeColour(me);
					end
					me.isInSetColour = false;
				case {'flashColourOut'}
					if length(v)==4 
						alpha = v(4);
					elseif isProperty(me,'alphaOut')
						alpha = me.dp.alphaOut;
					else
						alpha = me.alpha;
					end
					switch length(v)
						case 3
							v = [v(1:3) alpha];
						case 1
							v = [v v v alpha];
					end
					if isempty(me.flashColourOutTemp);me.flashColourOutTemp = v;end
					contrast = getP(me,'contrast');
					if ~me.inSetup && ~me.stopLoop && contrast < 1
						me.postSet = @computeColour(me);
					end
				case {'contrastOut'}
						while iscell(v); v = v{1}; end
						if isempty(me.colourOutTemp) && isProperty(me,'colourOut'); me.colourOutTemp = me.dp.colourOut;end
						if v < 1; me.postSet = @me.computeColour; end
				end
		end
		
	end
	
	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================
		
		% ===================================================================
		%> @brief computeColour triggered event
		%> Use an event to recalculate as get method is slower (called
		%> many more times), than an event which is only called on update
		% ===================================================================
		function computeColour(me)
			if me.inSetup || me.stopLoop; return; end
			me.stopLoop = true;
			if isempty(me.colourOutTemp) && isProperty(me,'colourOut'); me.colourOutTemp = me.dp.colourOut;end
			if me.dp.contrastOut < 1
				me.dp.colourOut = [me.mix(me.colourOutTemp(1:3)) me.dp.alphaOut];
				if ~isempty(me.dp.flashColourOut)
					me.dp.flashColourOut = [me.mix(me.flashColourOutTemp(1:3)) me.dp.alphaOut];
				end
			end
			me.stopLoop = false;
			me.setupFlash();
		end
		
		% ===================================================================
		%> @brief setupFlash
		%>
		% ===================================================================
		function setupFlash(me)
			me.flashState = me.flashOn;
			me.flashFG = me.dp.colourOut;
			me.flashCounter = 1;
			if me.doFlash
				if ~isempty(me.dp.flashColourOut)
					me.flashBG = [me.dp.flashColourOut(1:3) me.dp.alphaOut];
				else
					me.flashBG = [me.sM.backgroundColour(1:3) 0]; %make sure alpha is 0
				end
			end
			if me.flashState
				me.currentColour = me.flashFG;
			else
				me.currentColour = me.flashBG;
			end
		end
		
		% ===================================================================
		%> @brief linear interpolation between two arrays
		%>
		% ===================================================================
		function out = mix(me,c)
			out = me.sM.backgroundColour(1:3) * (1 - me.dp.contrastOut) + c(1:3) * me.dp.contrastOut;
		end
	end
end
