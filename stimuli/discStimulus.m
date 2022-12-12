% ========================================================================
%> @brief single disc stimulus, inherits from baseStimulus
%> DISCSTIMULUS single disc stimulus, inherits from baseStimulus
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef discStimulus < baseStimulus
	
	properties %--------------------PUBLIC PROPERTIES----------%
		%> type can be "simple" or "flash"
		type = 'simple'
		%> colour for flash, empty to inherit from screen background with 0 alpha
		flashColour = []
		%> time to flash on and off in seconds
		flashTime = [0.25 0.25]
		%> is the ON flash the first flash we see?
		flashOn = true
		%> contrast scales from foreground to screen background colour
		contrast = 1
		%> cosine smoothing sigma in pixels for mask
		sigma = 31.0
		%> use colour or alpha [default] channel for smoothing?
		useAlpha = true
		%> use cosine (0), hermite (1, default), or inverse hermite (2)
		smoothMethod = 1
	end
	
	properties (SetAccess = protected, GetAccess = public)
		%> stimulus family
		family = 'disc'
	end
	
	properties (SetAccess = private, GetAccess = public, Hidden = true)
		typeList = {'simple','flash'}
	end
	
	properties (Dependent = true, SetAccess = private, GetAccess = private)
		%> a dependant property to track when to switch from ON to OFF of
		%flash.
		flashSwitch
	end
	
	properties (SetAccess = protected, GetAccess = protected)
		res
		discSize
		radius
		%> change blend mode?
		changeBlend = false
		%> current flash state
		flashState
		%> internal counter
		flashCounter = 1
		%> the OFF colour of the flash, usually this is set to the screen background
		flashBG = [0.5 0.5 0.5]
		%> ON flash colour, reset on setup
		flashFG = [1 1 1]
		currentColour = [1 1 1]
		colourOutTemp = [1 1 1]
		flashColourOutTemp = [1 1 1]
		stopLoop = 0
		scale = 1
		allowedProperties = {'type','flashTime','flashOn','flashColour','contrast',...
			'sigma','useAlpha','smoothMethod'}
		ignoreProperties = {'flashSwitch','smoothMethod'};
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
		function me = discStimulus(varargin)
			args = octickaCore.addDefaults(varargin,...
				struct('name','Disc','colour',[1 1 0 1]));
			me=me@baseStimulus(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);
			
			me.isRect = true; %uses a rect for drawing?
			
			me.ignoreProperties = [ me.ignorePropertiesBase me.ignoreProperties ];
		end
		
		% ===================================================================
		%> @brief Setup the stimulus object. The major purpose of this is to create a series
		%> of properties that are copies of the user controlled ones. The user specifies
		%> properties in degrees etc., but internally we must convert to pixels etc. So the
		%> setup function uses dynamic transient properties, for each property we create a temporary 
		%> propertyOut which is used for the actual drawing/animation.
		%>
		%> @param sM handle to the current screenManager object
		% ===================================================================
		function setup(me,sM)
			
			reset(me);
			me.inSetup = true;
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
					me.dp.(p) = me.(fn{j}); %copy our property value to our tempory copy
				end
			end
			
			addRuntimeProperties(me); % create transient runtime action properties
			
			me.discSize = me.ppd * me.size;
			
			me.res = round([me.discSize me.discSize]);
			
			me.radius = floor(me.discSize/2);
			
			me.texture = CreateProceduralSmoothedDisc(sM.win, me.res(1), ...
						me.res(2), [0 0 0 0], me.radius, me.sigma, ...
						me.useAlpha, me.smoothMethod);
			
			if me.doFlash
				if ~isempty(me.dp.flashColourOut)
					me.flashBG = [me.dp.flashColourOut(1:3) me.dp.alphaOut];
				else
					me.flashBG = [me.sM.backgroundColour(1:3) 0]; %make sure alpha is 0
				end
				setupFlash(me);
			end
			
			if me.sM.blend && strcmpi(me.sM.srcMode,'GL_SRC_ALPHA') && strcmpi(me.sM.dstMode,'GL_ONE_MINUS_SRC_ALPHA')
				me.changeBlend = false;
			else
				me.changeBlend = true;
			end
			
			me.inSetup = false;
			computePosition(me);
			setRect(me);
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
			setRect(me);
			if me.doFlash; me.setupFlash; end
			if me.doAnimator; me.animator.reset(); end
		end
		
		% ===================================================================
		%> @brief Draw an structure for runExperiment
		%>
		%> @param sM runExperiment object for reference
		%> @return stimulus structure.
		% ===================================================================
		function draw(me)
			if me.isVisible && me.tick >= me.delayTicks && me.tick < me.offTicks
				%Screen('DrawTexture', windowPointer, texturePointer [,sourceRect] [,destinationRect] 
				%[,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader] 
				%[, specialFlags] [, auxParameters]);
				if me.mouseOverride && ~me.mouseValid; fprintf('II %i\n',me.tick);me.tick = me.tick + 1;return; end
				if me.changeBlend;Screen('BlendFunction', me.sM.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');end
				if me.doFlash == false
					Screen('DrawTexture', me.sM.win, me.texture, [], me.mvRect,...
					me.dp.angleOut, [], [], me.dp.colourOut, [], [],...
					[]);
				else
					Screen('DrawTexture', me.sM.win, me.texture, [], me.mvRect,...
					me.dp.angleOut, [], [], me.currentColour, [], [],...
					[]);
				end
				if me.changeBlend;Screen('BlendFunction', me.sM.win, me.sM.srcMode, me.sM.dstMode);end
				me.drawTick = me.drawTick + 1;
			end
			if me.isVisible; me.tick = me.tick + 1; end
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
						me.mvRect = CenterRectOnPoint(me.mvRect, me.mouseX, me.mouseY);
					end
					return
				end
				if me.doMotion && me.doAnimator
					me.mvRect = update(me.animator);
				elseif me.doMotion && ~me.doAnimator	
					me.mvRect=OffsetRect(me.mvRect,me.dX_,me.dY_);
				end
				if me.doFlash == true
					if me.flashCounter <= me.flashSwitch
						me.flashCounter=me.flashCounter+1;
					else
						me.flashCounter = 1;
						me.flashState = ~me.flashState;
						if me.flashState
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
			me.stopLoop = false; me.setLoop = 0;
			me.inSetup = false; me.isSetup = false;
			me.colourOutTemp = [];
			me.flashColourOutTemp = [];
			me.flashFG = [];
			me.flashBG = [];
			me.flashCounter = [];
			if isProperty(me,'texture')
				if ~isempty(me.texture) && me.texture > 0 && Screen(me.texture,'WindowKind') == -1
					try Screen('Close',me.texture); end %#ok<*TRYNC>
				end
				me.texture = []; 
			end
			me.removeTmpProperties;
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
    
    % ===================================================================
		%> @brief our fake set methods, hooks into dynamicprops subsasgn
		%>
		% ===================================================================
		function v = setOut(me, S, v)
      if ~isstruct(S) || ~strcmp(S(1).type, '.') || ~isfield(S,'subs'); return; end
      switch S(1).subs
        case 'sizeOut'
          v = v * me.ppd;
					if isProperty(me,'discSize') && ~isempty(me.discSize) && ~isempty(me.texture)
						me.scale = v / me.discSize;
						setRect(me);
					end
        case {'xPositionOut' 'yPositionOut'}
          v = v * me.ppd;
				case {'contrastOut'}
					if iscell(v); v = v{1}; end
					if ~me.inSetup && ~me.stopLoop && v < 1
						computeColour(me);
					end
			end
    end
		
	end %---END PUBLIC METHODS---%
	
	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================

		% ===================================================================
		%> @brief setRect
		%> setRect makes the PsychRect based on the texture and screen values
		%> this is modified over parent method as textures have slightly different
		%> requirements.
		% ===================================================================
		function setRect(me)
			me.dstRect = ScaleRect(Screen('Rect',me.texture), me.scale, me.scale);
			if me.mouseOverride && me.mouseValid
					me.dstRect = CenterRectOnPointd(me.dstRect, me.mouseX, me.mouseY);
			else
				if isProperty(me, 'angleOut')
					[sx, sy]=pol2cart(me.d2r(me.dp.angleOut),me.startPosition);
				else
					[sx, sy]=pol2cart(me.d2r(me.angle),me.startPosition);
				end
				me.dstRect=CenterRectOnPointd(me.dstRect,me.sM.xCenter,me.sM.yCenter);
				if isProperty(me, 'xPositionOut')
					me.dstRect=OffsetRect(me.dstRect,(me.dp.xPositionOut)*me.ppd,(me.dp.yPositionOut)*me.ppd);
				else
					me.dstRect=OffsetRect(me.dstRect,me.xPosition+(sx*me.ppd),me.yPosition+(sy*me.ppd));
				end
			end
			me.mvRect=me.dstRect;
			me.setAnimationDelta();
		end
		
		% ===================================================================
		%> @brief computeColour triggered event
		%> Use an event to recalculate as get method is slower (called
		%> many more times), than an event which is only called on update
		% ===================================================================
		function computeColour(me,~,~)
			if me.inSetup || me.stopLoop; return; end
			me.stopLoop = true;
			me.dp.colourOut = [me.mix(me.dp.colourOutTemp(1:3)) me.dp.alphaOut];
			if ~isempty(me.flashColourOut)
				me.dp.flashColourOut = [me.mix(me.dp.flashColourOutTemp(1:3)) me.dp.alphaOut];
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