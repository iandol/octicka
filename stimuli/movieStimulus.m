% ========================================================================
%> @brief movieStimulus is the class for movie based stimulus objects
%>
%>
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================	
classdef movieStimulus < baseStimulus	
	properties %--------------------PUBLIC PROPERTIES----------%
		type = 'movie'
		%> the direction of the whole object - i.e. the motion direction 
		%> object can move in (different to the angle).
		direction  = 0
		%> do we lock the texture angle to the direction? If so what is the offset
		%(0 = parallel, 90 = orthogonal etc.)
		lockAngle = []
		%> the name and path of the movie file, if empty a default will be used
		fileName = ''
		%> selection if N > 0, then this is a number of images from 1:N, e.g.
		%> fileName = base.jpg, selection=5, then base1.jpg - base5.jpg
		%> update() will randomly select one from this group.
		selection		= 0
		%> do we block when getting a frame? This is important, as if it is 1
		%> then you will drop frames waiting for the the synced video frame.
		%> Set to 0 this class uses double buffering to keep drawing the previous frame
		%> unitl a new frame is ready, ensuring other stimuli animate
		%> smoothly alongside the video. 
		blocking = 0
		%> pixel format for opening movie? 6 is more efficient if H264
		%> used. 1 = Luminance/Greyscale image, 2 = Luminance+Alpha, 
		%> 3 = RGB 8 bit per channel, 4 = RGBA8, 5 = YUV 4:2:2 packed pixel format 
		%> on some graphics hardware, 6 = YUV-I420 planar format, using GLSL shaders 
		%> for color space conversion on suitable graphics cards. 
		%> 7 or 8 = Y8-Y800 planar format, using GLSL shaders, 
		%> 9 = 16 bit Luminance, 10 = 16 bpc RGBA image
		pixelFormat = []
		%> how many seconds to preload, -1 tries all
		preloadSecs = -1
		%> additional special flags, numbers can be added together
		%> 1 = Use YUV video decoding instead of RGBA
		%> 2 = linux with psychportaudio
		%> 4 = draw motion vectors on top of decoded video frames
		%> 8 = skip all B-Frames during decoding to reduce processor load on very slow machines
		%> 16 = convert all video textures immediately into a format which makes them useable as offscreen windows
		%> 32,64,128 = different loop strategies
		%> 256 = revent automatic deinterlacing of video
		%> 512 = marks the movie as encoded in Psychtoolbox's own proprietary 16 bpc high precision format
		%> 1024 = video frames are encoded as raw Bayer sensor data
		specialFlagsOpen = []
		%> special flags for 'GetMovieImage'
		%> 1 = use GL_TEXTURE_2D
		%> 2 = high precision
		%> 8 = no mipmap with GL_TEXTURE_2D
		%> 32 = prevent closing the texture by a call to Screen('Close')
		specialFlagsFrame = []
		%> special flags for 'GetMovieImage'
		%> 1 = don't return any time info (maybe slightly faster?)
		%> 2 = don't return any textures, for bechmarking.
		specialFlags2Frame = 1;
		%> how to handle looping (1=PTB default)
		loopStrategy = 1
		%> mask out a colour? e.g. [0 0 0]
		mask = []
		%> mask tolerance
		maskTolerance = [];
		%> if movie has transparency, enforce opengl blending?
		enforceBlending = false
	end
	
	properties (SetAccess = protected, GetAccess = public)
		%> list of imagenames if selection > 0
		fileNames = {};
		%> current randomly selected image
		currentMovie				= ''
		%> scale is dependent on stimulus size and movie width
		scale = 1
		family = 'movie'
		%> handle from OpenMovie
		movie
		duration
		fps
		width
		height
		count
	end
	
	properties (SetAccess = protected, GetAccess = public, Transient = true, Hidden = true)
		typeList = {'movie'}
		fileNameList = 'filerequestor';
		%> texture buffer for non-blocking movie playback, this is the
		%> previous frame until a new frame is available
		buffertex = []
		%> shader for masking
		shader
	end

	properties (SetAccess = protected, GetAccess = ?baseStimulus)
		%> properties to not show in the UI panel
		ignorePropertiesUI = {'alpha','type'}
	end
	
	properties (SetAccess = protected, GetAccess = protected)
		thisMovie			= ''
		msrcMode			= 'GL_SRC_ALPHA'
		mdstMode			= 'GL_ONE_MINUS_SRC_ALPHA'
		%> allowed properties passed to object upon construction
		allowedProperties = {'fileName', 'blocking', 'pixelFormat', 'preloadSecs', ...
			'specialFlagsOpen', 'specialFlagsFrame', 'specialFlags2Frame', 'loopStrategy', ...
			'mask', 'maskTolerance', 'enforceBlending', 'direction','selection'}
		%> properties to not create transient copies of during setup phase
		ignoreProperties = {'buffertex', 'shader', 'screenVals', 'movie', 'duration', ...
			'fps', 'width', 'height', 'count', 'scale', 'fileName', 'pixelFormat', ...
			'preloadSecs', 'specialFlagsOpen', 'specialFlagsFrame', 'specialFlags2Frame', ...
			'loopStrategy'}
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
		function me = movieStimulus(varargin)
			args = octickaCore.addDefaults(varargin,...
				struct('name','movie','size',0));
			me=me@baseStimulus(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);
			
			me.isRect = true; %uses a rect for drawing
			
			checkFileName(me);
			
			me.ignoreProperties = [me.ignorePropertiesBase me.ignoreProperties];
			me.logOutput('constructor','Movie Stimulus initialisation complete');
		end
		
		% ===================================================================
		%> @brief Setup this object in preperation for use
		%> When displaying a stimulus object, the main properties that are to be
		%> modified are copied into cache copies of the property, both to convert from 
		%> user-friendly visual description (c/d, Hz, degrees) to
		%> computer pixels metrics; and to be animated and modified as independant
		%> variables. So xPosition is copied to xPositionOut and converted from
		%> degrees to pixels. The animation and drawing functions use these modified
		%> properties, and when they are updated, for example to change to a new
		%> xPosition, internal methods ensure reconversion and update any dependent
		%> properties. This method initialises the object in preperation for display.
		%>
		%> @param sM screenManager object for reference
		% ===================================================================
		function setup(me, sM)
			
			reset(me);
			me.inSetup = true; me.isSetup = false;
			if isempty(me.isVisible); me.show; end
			
			me.sM = sM;
			if ~sM.isOpen; error('Screen needs to be Open!'); end
			
			checkFileName(me);
			
			% On ARM set the default pixelFormat to 6 for shader based decode.
			% On a RaspberryPi-4 this makes a world of difference when playing
			% HD movies, between slow-motion 2 fps and proper 24 fps playback.
			if isempty(me.pixelFormat) && IsARM
				me.pixelFormat = 6;
			end
			
			me.ppd=sM.ppd;
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
			
			me.shader = [];
			if ~isempty(me.mask)
				me.shader = CreateSinglePassImageProcessingShader(me.sM.win, 'BackgroundMaskOut', me.mask, me.maskTolerance);
			end
			
			me.inSetup = false; me.isSetup = true;
			loadMovie(me);
			computePosition(me)
			setRect(me);

		end

		% ===================================================================
		%> @brief Update this stimulus object structure for screenManager
		%>
		% ===================================================================
		function update(me)
			Screen('PlayMovie', me.movie, 0);
			Screen('SetMovieTimeIndex', me.movie, 0); %reset movie
			if ~isempty(me.texture) && me.texture > 0 && Screen(me.texture,'WindowKind') == -1
				try Screen('Close',me.texture); end %#ok<*TRYNC>
			end
			if ~isempty(me.buffertex) && me.buffertex > 0 && Screen(me.buffertex,'WindowKind') == -1
				try Screen('Close',me.buffertex); end 
			end
			me.texture = []; me.buffertex = [];
			if me.dp.sizeOut > 0
				me.scale = me.dp.sizeOut / (me.width / me.ppd);
			end
			resetTicks(me);
			fprintf('selectionOut = %i\n',me.selectionOut);
			if ~matches(me.currentMovie,me.fileNames{me.selectionOut})
				me.currentMovie = me.fileNames{me.selectionOut};
				loadMovie(me);
			end
			computePosition(me);
			setRect(me);
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
			else
				fprintf('--->>> movieStimulus invalid mvRect\n');
			end
		end
		
		% ===================================================================
		%> @brief Draw this stimulus object
		%>
		% ===================================================================
		function draw(me)
			if me.isVisible && me.tick >= me.delayTicks && me.tick < me.offTicks
				if me.tick == 0 || (me.delayTicks > 0 && me.tick == me.delayTicks) 
					Screen('PlayMovie', me.movie, 1, me.loopStrategy); 
				end
				if ~isempty(me.lockAngle); angle = me.dp.directionOut+me.lockAngle; else; angle = me.dp.angleOut; end
				if me.enforceBlending; Screen('BlendFunction', me.sM.win, me.msrcMode, me.mdstMode); end
				me.texture = Screen('GetMovieImage', me.sM.win, me.movie, me.blocking);
				if ~isempty(me.texture) && me.texture > 0
					if ~isempty(me.buffertex) && me.buffertex > 0 ...
					&& Screen(me.buffertex,'WindowKind') == -1
						Screen('Close', me.buffertex);
					end
					Screen('DrawTexture', me.sM.win, me.texture, [], me.mvRect,...
						angle,[],[],[],me.shader);
					me.buffertex = me.texture; %copy new texture to buffer
					me.texture = [];
				elseif ~isempty(me.buffertex) && me.buffertex > 0
					Screen('DrawTexture', me.sM.win, me.buffertex, [], me.mvRect,...
						angle,[],[],[],me.shader)
				end
				if me.enforceBlending; Screen('BlendFunction', me.sM.win, me.sM.srcMode, me.sM.dstMode); end
				me.drawTick = me.drawTick + 1;
			end
			if me.isVisible; me.tick = me.tick + 1; end
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
						me.mvRect = CenterRectOnPoint(me.mvRect, me.mouseX, me.mouseY);
					end
					return
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
			resetTicks(me);
			me.scale = 1;
			me.mvRect = [];
			me.dstRect = [];
			me.removeTmpProperties;
			ndrop=-1;
			if ~isempty(me.texture) && me.texture>0 ...
					&& Screen(me.texture,'WindowKind')==-1
				try Screen('Close',me.texture); end
			end
			if ~isempty(me.buffertex) && me.buffertex>0 ...
					&& (isempty(me.texture) || me.texture ~= me.buffertex) ...
					&& Screen(me.buffertex,'WindowKind')==-1
				try Screen('Close',me.buffertex); end
			end
			me.buffertex = []; me.texture = [];
			if ~isempty(me.movie)
				try ndrop=Screen('Playmovie', me.movie, 0); end %#ok<*TRYNC>
				fprintf('---> Number of dropped movie frames: %i\n',ndrop)
				try Screen('CloseMovie', me.movie); end
			end
			me.shader = [];
			me.movie = [];
			me.duration = [];
			me.fps = [];
			me.width = [];
			me.height = [];
			me.inSetup = false; me.isSetup = false;
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
				case {'sizeOut','xPositionOut' 'yPositionOut'}
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
		
		% ===================================================================
		%> @brief 
		%>
		% ===================================================================
		function findFile(me, dir)
			if ~exist('dir','var'); dir = false; end
			if dir
				p = uigetdir('Select Movie Files Dir');
				f = '';
			else
				[f,p] = uigetfile({ '*.*',  'All Files (*.*)'},'Select Movie File');
			end
			if ischar(f)
				me.fileName = [p f];
			end
			checkFileName(me);
			fprintf('--->>> Found these movies:\n');
			for i = 1:length(me.fileNames)
				fprintf('\t %s\n',me.fileNames{i});
			end
		end
		
	end
	
	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================
	
		% ===================================================================
		%> @brief loadMovie
		% ===================================================================
		function loadMovie(me)
			if ~me.isSetup; return; end
			if ~isempty(me.movie)
				try ndrop=Screen('Playmovie', me.movie, 0); end %#ok<*TRYNC>
				fprintf('---> Number of dropped movie frames: %i\n',ndrop)
				try Screen('CloseMovie', me.movie); end
				me.movie = []; me.width = []; me.height = [];
			end
			t=tic;
			[me.movie, me.duration, me.fps, me.width, me.height] = Screen('OpenMovie', ...
				me.sM.win, me.currentMovie, [], me.preloadSecs, me.specialFlagsOpen, me.pixelFormat);
			fprintf('\n--->>> movieStimulus: %s\n\t%.2f seconds duration, %i frames @ %f fps, w x h = %i x %i, in %ims\n', ...
				me.currentMovie, me.duration, me.count, me.fps, me.width, me.height, round(toc(t)*1e3));
			fprintf('\tBlocking: %i | Loop: %i | Preloadsecs: %i | Pixelformat: %i | Flags: %i\n', me.blocking, ...
				me.loopStrategy, me.preloadSecs, me.pixelFormat, me.specialFlagsOpen);
		end

		% ===================================================================
		%> @brief setRect
		%>  setRect makes the PsychRect based on the texture and screen values
		%>  This is overridden from parent class so we can scale texture
		%>  using the size value
		% ===================================================================
		function setRect(me)
			if ~isempty(me.movie)
				if me.sizeOut > 0
					me.scale = me.dp.sizeOut / (me.width / me.ppd);
				end
				me.dstRect = ScaleRect([0 0 me.width me.height], me.scale, me.scale);
				if me.mouseOverride && me.mouseValid
					me.dstRect = CenterRectOnPointd(me.dstRect, me.mouseX, me.mouseY);
				else
					me.dstRect=CenterRectOnPointd(me.dstRect, me.xFinal, me.yFinal);
				end
				if me.verbose
					fprintf('---> stimulus TEXTURE dstRect = %5.5g %5.5g %5.5g %5.5g\n',me.dstRect(1), me.dstRect(2),me.dstRect(3),me.dstRect(4));
				end
				me.mvRect = me.dstRect;
			end
		end
		
		% ===================================================================
		%> @brief 
		%>
		% ===================================================================
		function checkFileName(me)
			me.fileName = regexprep(me.fileName, '^~\/', [getenv('HOME') filesep]);
			if isempty(me.fileName) || (me.selection==0 &&	exist(me.fileName,'file') ~= 2 && exist(me.fileName,'file') ~= 7)%use our default
				p = mfilename('fullpath');
				p = fileparts(p);
				me.fileName = [p filesep 'monkey-dance.avi'];
				me.fileNames{1} = me.fileName;
				me.selection = 1;
				fprintf('---> movieStimulus: Didn''t find specified file so replacing with default movie %s\n',me.fileName);
			elseif exist(me.fileName,'dir') == 7
				findFiles(me);
			elseif me.selection>1
				[p,f,e]=fileparts(me.fileName);
				for i = 1:me.selection
					me.fileNames{i} = [p filesep f num2str(i) e];
					if ~exist(me.fileNames{i},'file');warning('Movie %s not available!',me.fileNames{i});end
				end
			elseif exist(me.fileName,'file') == 2
				me.selection = 1;
				me.fileNames{1} = me.fileName;
			end
			me.currentMovie = me.fileNames{me.selection};
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
					if regexpi(e,'mp4|avi|mpeg')
						n = n + 1;
						me.fileNames{n} = [me.fileName filesep f e];
						me.fileNames{n} = regexprep(me.fileNames{n},'\/\/','/');
					end
				end
				me.selection = length(me.fileNames);
			end
		end
		
	end %-------END PROTECTED METHODS-----%

end %-------END CLASSDEF-----%
