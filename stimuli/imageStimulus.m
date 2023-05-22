% ========================================================================
%> @brief textureStimulus
%>
%> Superclass providing basic structure for texture stimulus classes
%>
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef imageStimulus < baseStimulus
	properties %--------------------PUBLIC PROPERTIES----------%
		type						= 'picture'
		%> filename to load, if dir load all images sequentially
		fileName					= ''
		%> multipleImages if N > 0, then this is a number of images from 1:N, e.g.
		%> fileName = base.jpg, multipleImages=5, then base1.jpg - base5.jpg
		%> update() will randomly select one from this group.
		multipleImages				= 0
		%> contrast multiplier
		contrast					= 1
		%> precision, 0 keeps 8bit, 1 16bit, 2 32bit
		precision					= 0
		%> special flags: 0 = hardware filter, 2 = PTB
		%> filter, 4 = fast texture creation, 8 = prevent
		%> auto mip-map generation, 32 = stop Screen('Close')
		%> clearing texture
		specialFlags				= []
	end

	properties (SetAccess = protected, GetAccess = public)
		%> scale is set by size
		scale						= 1
		%>
		family						= 'texture'
		%> current randomly selected image
		currentImage				= ''
		%>
		width
		%>
		height
	end

	properties (SetAccess = protected, GetAccess = public, Hidden = true)
		typeList			= {'picture'}
		fileNameList		= 'filerequestor';
		interpMethodList	= {'nearest','linear','spline','cubic'}
		%> list of imagenames if multipleImages > 0
		fileNames			= {};
		%> properties to ignore in the UI
		ignorePropertiesUI	= {}
		%> image data
		matrix
	end

	properties (Access = protected)
		%> allowed properties passed to object upon construction
		allowedProperties	= {'type', 'fileName', 'multipleImages', 'contrast', ...
			'scale'}
		%>properties to not create transient copies of during setup phase
		ignoreProperties	= {'type', 'scale', 'fileName', 'multipleImages'}
	end

	%=======================================================================
	methods %------------------PUBLIC METHODS
	%=======================================================================

		% ===================================================================
		%> @brief Class constructor
		%>
		%> This parses any input values and initialises the object.
		%>
		%> @param varargin are passed as a list of parametoer or a structure
		%> of properties which is parsed.
		%>
		%> @return instance of octicka class.
		% ===================================================================
		function me = imageStimulus(varargin)
			args = octickaCore.addDefaults(varargin,struct('size',0,...
				'name','Image'));
			me=me@baseStimulus(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);

			me.isRect = true; %uses a rect for drawing

			checkFileName(me);

			me.ignoreProperties = [me.ignorePropertiesBase me.ignoreProperties];
			me.logOutput('constructor','Image Stimulus initialisation complete');
		end

		% ===================================================================
		%> @brief Setup this object in preperation for use
		%> When displaying a stimulus object, the main properties that are to be
		%> modified are copied into cache copies of the property, both to convert from
		%> visual description (c/d, Hz, degrees) to
		%> computer metrics; and to be animated and modified as independant
		%> variables. So xPosition is copied to xPositionOut and converted from
		%> degrees to pixels. The animation and drawing functions use these modified
		%> properties, and when they are updated, for example to change to a new
		%> xPosition, internal methods ensure reconversion and update any dependent
		%> properties. This method initialises the object in preperation for display.
		%>
		%> @param sM screenManager object for reference
		%> @param in matrix for conversion to a PTB texture
		% ===================================================================
		function setup(me,sM,in)
			if ~exist('in','var');in = []; end
			reset(me); %reset object back to its initial state
			me.inSetup = true; me.isSetup = false;
			if isempty(me.isVisible); show(me); end

			checkFileName(me);

			me.sM = sM;
			if ~sM.isOpen; error('Screen needs to be Open!'); end
			me.ppd = sM.ppd;
			me.screenVals = sM.screenVals;
			me.texture = []; %we need to reset this

			me.dp = struct;
			fn = fieldnames(me);
			for j=1:length(fn)
				if ~ismember(fn{j}, me.ignoreProperties)
					prop = [fn{j} 'Out'];
					p = addProperty(me, prop);
					v = me.setOut(prop,me.(fn{j})); % our pseudo set method
					me.dp.(p) = v; %copy our property value to our tempory copy
				end
			end

			addRuntimeProperties(me);

			loadImage(me, in);

			if me.dp.sizeOut > 0
				me.scale = me.dp.sizeOut / (me.width / me.ppd);
			end

			me.inSetup = false; me.isSetup = true;

			computePosition(me);
			setRect(me);

		end

		% ===================================================================
		%> @brief Load an image
		%>
		% ===================================================================
		function loadImage(me,in)
			ialpha = [];
			if ~exist('in','var'); in = []; end
			if ~isempty(in) && ischar(in)
				[me.matrix, ~, ialpha] = imread(in);
				me.currentImage = in;
			elseif ~isempty(in) && isnumeric(in)
				me.matrix = in;
				me.currentImage = '';
			elseif ~isempty(me.fileNames{1}) && exist(me.fileNames{1},'file')
				[me.matrix, ~, ialpha] = imread(me.fileNames{1});
				me.currentImage = me.fileNames{1};
			else
				if me.dp.sizeOut <= 0; sz = 2; else; sz = me.dp.sizeOut; end
				me.matrix = uint8(ones(sz*me.ppd,sz*me.ppd,3)*255); %white texture
				me.currentImage = '';
			end

			if me.precision > 0
				me.matrix = double(me.matrix)/255;
			end

			me.width = size(me.matrix,2);
			me.height = size(me.matrix,1);
			me.matrix = me.matrix .* me.dp.contrastOut;

			if isempty(ialpha)
				if isfloat(me.matrix)
					me.matrix(:,:,4) = me.dp.alphaOut;
				else
					me.matrix(:,:,4) = uint8(me.dp.alphaOut .* 255);
				end
			else
				if isfloat(me.matrix)
					me.matrix(:,:,4) = double(ialpha);
				else
					me.matrix(:,:,4) = ialpha;
				end
			end

			if isempty(me.specialFlags) && isinteger(me.matrix(1))
				me.specialFlags = 4; %4 is optimization for uint8 textures. 0 is default
			end
			me.texture = Screen('MakeTexture', me.sM.win, me.matrix, 1, me.specialFlags, me.precision);
			me.logOutput('loadImage',['Load: ' regexprep(me.currentImage,'\\','/')]);
		end

		% ===================================================================
		%> @brief Update this stimulus object structure for screenManager
		%>
		% ===================================================================
		function update(me)
			if me.multipleImages > 0
				if ~isempty(me.texture) && me.texture > 0 && Screen(me.texture,'WindowKind') == -1
					try Screen('Close',me.texture); end %#ok<*TRYNC>
				end
				me.loadImage(me.fileNames{randi(me.multipleImages)});
			end
			if me.dp.sizeOut > 0
				me.scale = me.dp.sizeOut / (me.width / me.ppd);
			end
			resetTicks(me);
			computePosition(me);
			setRect(me);
		end

		% ===================================================================
		%> @brief Draw this stimulus object
		%>
		% ===================================================================
		function draw(me,win)
			if me.isVisible && me.tick >= me.delayTicks && me.tick < me.offTicks
				if ~exist('win','var');win = me.sM.win; end
				% Screen('DrawTexture', windowPointer, texturePointer
				% [,sourceRect] [,destinationRect] [,rotationAngle]
				% [, filterMode] [, globalAlpha] [, modulateColor]
				% [, textureShader] [, specialFlags] [, auxParameters]);
				Screen('DrawTexture', win, me.texture, [], me.mvRect, me.dp.angleOut,...
					[], me.dp.alphaOut, me.dp.colourOut);
			end
			me.tick = me.tick + 1;
		end

		% ===================================================================
		%> @brief Animate an structure for screenManager
		%>
		% ===================================================================
		function animate(me)
			if me.isVisible && me.tick >= me.delayTicks
				if me.mouseOverride
					getMousePosition(me);
					if me.mouseValid
						me.mvRect = CenterRectOnPointd(me.mvRect, me.mouseX, me.mouseY);
					end
				end
				if me.doMotion == 1
					me.mvRect=OffsetRect(me.mvRect,me.dX_,me.dY_);
				end
			end
		end

		% ===================================================================
		%> @brief Reset an structure for screenManager
		%>
		% ===================================================================
		function reset(me)
			if ~isempty(me.texture) && me.texture > 0 && Screen(me.texture,'WindowKind') == -1
				try Screen('Close',me.texture); end %#ok<*TRYNC>
			end
			resetTicks(me);
			me.texture=[];
			me.scale = 1;
			me.mvRect = [];
			me.dstRect = [];
			removeTmpProperties(me);
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
			elseif isstruct(S) && strcmp(S(1).type, '.') && isfield(S,'subs')
				prop = S(1).subs;
			else
				return;
			end
			switch prop
				case {'xPositionOut' 'yPositionOut'}
					v = v * me.ppd;
				case {'contrastOut'}
					if iscell(v); v = v{1}; end
					if ~me.inSetup && ~me.stopLoop && v < 1
						computeColour(me);
					end
			end
		end

		% ===================================================================
		%> @brief Update only position info, faster and doesn't reset movie
		%>
		% ===================================================================
		function updatePositions(me,x,y)
			me.xFinal = x;
			me.yFinal = y;
			if length(me.mvRect) == 4
				me.mvRect=CenterRectOnPointd(me.mvRect, me.xFinal, me.yFinal);
			end
		end

	end

	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================

		% ===================================================================
		%> @brief setRect
		%>  setRect makes the PsychRect based on the texture and screen values
		%>  This is overridden from parent class so we can scale texture
		%>  using the size value
		% ===================================================================
		function setRect(me)
			if ~isempty(me.texture)
				%setRect@baseStimulus(me) %call our superclass version first
				me.dstRect=Screen('Rect',me.texture);
				me.dstRect = ScaleRect(me.dstRect, me.scale, me.scale);
				if me.mouseOverride && me.mouseValid
					me.dstRect = CenterRectOnPointd(me.dstRect, me.mouseX, me.mouseY);
				else
					me.dstRect=CenterRectOnPointd(me.dstRect, me.xFinal, me.yFinal);
				end
				if me.verbose
					fprintf('---> stimulus TEXTURE dstRect = %5.5g %5.5g %5.5g %5.5g width = %.2f height = %.2f\n',...
						me.dstRect(1), me.dstRect(2),me.dstRect(3),me.dstRect(4),...
						me.dstRect(3)-me.dstRect(1),me.dstRect(4)-me.dstRect(2));
				end
				me.mvRect = me.dstRect;
			end
		end

		% ===================================================================
		%> @brief
		%>
		% ===================================================================
		function checkFileName(me)
			if isempty(me.fileName) || (me.multipleImages==0 &&	exist(me.fileName,'file') ~= 2 && exist(me.fileName,'file') ~= 7)%use our default
				p = mfilename('fullpath');
				p = fileparts(p);
				me.fileName = [p filesep 'Bosch.jpeg'];
				me.fileNames{1} = me.fileName;
			elseif exist(me.fileName,'dir') == 7
				findFiles(me);
			elseif exist(me.fileName,'file') == 2
				me.fileNames{1} = me.fileName;
			elseif exist(me.fileName,'file') ~= 2 && me.multipleImages>1
				[p,f,e]=fileparts(me.fileName);
				for i = 1:me.multipleImages
					me.fileNames{i} = [p filesep f num2str(i) e];
				end
			end
		end



		% ===================================================================
		%> @brief findFiles
		%>
		% ===================================================================
		function findFiles(me)
			if exist(me.fileName,'dir') == 7
				d = dir(me.fileName);
				n = 0;
				for i = 1: length(d)
					if d(i).isdir;continue;end
					[~,f,e]=fileparts(d(i).name);
					if regexpi(e,'png|jpeg|jpg|bmp|tif')
						n = n + 1;
						me.fileNames{n} = [me.fileName filesep f e];
						me.fileNames{n} = regexprep(me.fileNames{n},'\/\/','/');
					end
					me.multipleImages = length(me.fileNames);
				end
			end
		end

	end

end
