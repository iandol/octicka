% ========================================================================
classdef touchManager < octickaCore
%> @class touchManager
%> @brief Manages touch screens (wraps the PTB TouchQueue* functions)
%>
%> TOUCHMANAGER -- call this and setup with screen manager, then run your
%> task. This class can handles touch windows, exclusion zones and more for
%> multiple touch screens.
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================

	%--------------------PUBLIC PROPERTIES----------%
	properties
		%> which touch device to connect to?
		device				= 1
		%> use the mouse instead of the touch screen for debugging
		isDummy				= false
		%> accept window (circular when radius is 1 value, rectangular when radius = [width height])
		%> doNegation allows to return -100 (like exclusion) if touch is outside window.
		%> when using the testHold etc functions:
		%> init: a timer that measures time to first touch
		%> hold: a timer that determines how long to hold
		%> release: a timer to determine the time after hold to release the window
		window				= struct('X', 0, 'Y', 0, 'radius', 2, 'doNegation', false, 'negationBuffer', 2,...
								'strict', true,...
								'init', 3, 'hold', 1, 'release', 1);
		%> Use exclusion zones where no touch allowed: [left,top,right,bottom]
		%> Add rows to generate multiple exclusion zones.
		exclusionZone		= []
		%> verbosity
		verbose				= false
	end

	properties (Hidden = true)
		%> number of slots for touch events
		nSlots				= 1e5
		%> size in degrees around the window for negation to trigger
		negationBuffer		= 2
	end

	properties (SetAccess=private, GetAccess=public)
		x					= []
		y					= []
		win					= []
		hold				= []
		eventNew			= false
		eventMove			= false
		eventPressed		= false
		eventRelease		= false
		eventID				= [];
		wasHeld				= false
		wasNegation			= false
		isSearching			= false
		isReleased			= false
		isOpen				= false
		isQueue				= false
		devices				= []
		names				= []
		allInfo				= []
		event				= []
	end

	properties (Access = private)
		pressed				= false
		ppd					= 36
		screen				= []
		swin				= []
		screenVals			= []
		allowedProperties	= {'isDummy','device','verbose','window','nSlots','negationBuffer'}
		holdTemplate		= struct('N',0,'touched',false,'start',0,'now',0,'total',0,'search',0,...
							'init',0,'length',0,'releaseinit',0,'release',0)
	end

	%=======================================================================
	methods %------------------PUBLIC METHODS
	%=======================================================================

		% ===================================================================CONSTRUCTOR
		function me = touchManager(varargin)
		%> @fn touchManager
		%> @brief Class constructor
		%>
		%> Initialises the class sending any parameters to parseArgs.
		%>
		%> @param varargin are passed as a structure of properties which is
		%> parsed.
		%> @return instance of the class.
		% ===================================================================
			args = octickaCore.addDefaults(varargin,struct('name','touchManager'));
			me = me@octickaCore(args); %superclass constructor
			me.parseArgs(args, me.allowedProperties);
			
			try [me.devices,me.names,me.allInfo] = GetTouchDeviceIndices([], 1); end %#ok<*TRYNC>
			me.hold = me.holdTemplate;
		end

		% ===================================================================SETUP
		function setup(me, sM)
		%> @fn setup(me, sM)
		%>
		%> @param sM screenManager to use
		%> @return
		% ===================================================================
			me.isOpen = false; me.isQueue = false;
			if isa(sM,'screenManager') && sM.isOpen
				me.screen = sM;
				me.swin = sM.win;
				me.ppd = sM.ppd;
				me.screenVals = sM.screenVals;
			else
				error('Need to pass an open screenManager object!');
			end
			try [me.devices,me.names,me.allInfo] = GetTouchDeviceIndices([], 1); end
			if me.isDummy
				me.comment = 'Dummy Mode Active';
				fprintf('--->touchManager: %s\n',me.comment);
			elseif isempty(me.devices)
				me.comment = 'No Touch Screen are available, please check USB!';
				fprintf('--->touchManager: %s\n',touchme.comment);
			elseif length(me.devices)==1
				me.comment = sprintf('found ONE Touch Screen: %s',me.names{1});
				fprintf('--->touchManager: %s\n',me.comment);
			elseif length(me.devices)==2
				me.comment = sprintf('found TWO Touch Screens plugged %s %s',me.names{1},me.names{2});
				fprintf('--->touchManager: %s\n',me.comment);
			end
		end

		% ===================================================================
		function createQueue(me)
		%> @fn createQueue(me)
		%>
		%> @param choice which touch device to use, default uses me.device
		%> @return
		% ===================================================================
			if me.isDummy; me.isQueue = true; return; end
			try
				TouchQueueCreate(me.swin, me.devices(me.device), me.nSlots);
			catch
				warning('touchManager: Cannot create touch queue!');
			end
			me.isQueue = true;
			if me.verbose; logOutput(me,'createQueue','Created...'); end
		end

		% ===================================================================
		function start(me)
		%> @fn start(me)
		%>
		%> @return
		% ===================================================================
			if me.isDummy; me.isOpen = true; return; end
			if ~me.isQueue; createQueue(me); end
			TouchQueueStart(me.devices(me.device));
			me.isOpen = true;
			if me.verbose; logOutput(me,'start','Started queue...'); end
		end

		% ===================================================================
		function stop(me)
		%> @fn stop(me)
		%>
		%> @return
		% ===================================================================
			if me.isDummy; me.isOpen = false; return; end
			TouchQueueStop(me.devices(me.device));
			me.isOpen = false; me.isQueue = false;
			if me.verbose; logOutput(me,'stop','Stopped queue...'); end
		end

		% ===================================================================
		function close(me)
		%> @fn close(me, choice)
		%>
		%> @param choice which touch device to use, default uses me.device
		%> @return
		% ===================================================================
			me.isOpen = false;
			me.isQueue = false;
			if me.isDummy; return; end
			if ~exist('choice','var') || isempty(choice); choice = me.device; end
			for i = 1:length(choice)
				TouchQueueRelease(me.devices(me.device));
			end
			if me.verbose; logOutput(me,'close','Closed...'); end
		end

		% ===================================================================
		function flush(me)
		%> @fn flush(me)
		%>
		%> @param 
		%> @return
		% ===================================================================
			if me.isDummy; return; end
			TouchEventFlush(me.devices(me.device));
		end

		% ===================================================================
		function navail = eventAvail(me)
		%> @fn eventAvail(me)
		%>
		%> @param
		%> @return nAvail number of available events
		% ===================================================================
			navail = [];
			if me.isDummy
				[~, ~, b] = GetMouse;
				if any(b); navail = true; end
			else
				navail(i)=TouchEventAvail(me.devices(me.device)); %#ok<*AGROW>
			end
		end

		% ===================================================================
		function event = getEvent(me)
		%> @fn getEvent
		%>
		%> @param
		%> @return event structure
		% ===================================================================
			persistent lastPressed
			if isempty(lastPressed); lastPressed = false; end
			event = [];
			if me.isDummy
				[mx, my, b] = GetMouse(me.swin);
				if any(b) && ~lastPressed
					type = 2; motion = false; press = true;  lastPressed = true;
				elseif any(b) && lastPressed
					type = 3; motion = true; press = true;  lastPressed = true;
				elseif lastPressed && ~any(b)
					type = 4; motion = false; press = false; lastPressed = false;
				else
					type = -1; motion = false; press = 0;  lastPressed = false;
				end
				if type > 0
					event = struct('Type',type,'Time',GetSecs,...
					'X',mx,'Y',my,'ButtonStates',b,...
					'NormX',mx/me.screenVals.width,'NormY',my/me.screenVals.height, ...
					'MappedX',mx,'MappedY',my,...
					'Pressed',press,'Motion',motion);
				end
			else
				event = TouchEventGet(me.devices(me.device), me.swin, 0);
			end
			me.eventNew = false; me.eventMove = false; me.eventRelease = false; me.eventPressed = false;
			if ~isempty(event)
				me.eventID = event.Keycode;
				switch event.Type
					case 2 %NEW
						me.eventNew = true;
						me.eventPressed = true;
					case 3 %MOVE
						me.eventMove = true;
						me.eventPressed = true;
					case 4 %RELEASE
						me.eventRelease = true;
					case 5 %ERROR
						disp('Event lost!');
						event = [];
				end
				me.event = event;
			end
		end

		% ===================================================================
		function resetAll(me)
		%> @fn resetAll
		%>
		%> @param
		%> @return
		% ===================================================================
			me.hold			= me.holdTemplate;
			me.x			= [];
			me.y			= [];
			me.win			= [];
			me.wasHeld		= false;
			me.isReleased	= false;
			me.wasNegation	= false;
			me.isSearching	= false;
			me.eventNew		= false;
			me.eventMove	= false;
			me.eventPressed	= false;
			me.eventRelease	= false;
			me.eventID 		= [];
			me.event		= [];
		end

		% ===================================================================
		function [result, win, wasEvent] = checkTouchWindows(me, windows, panelType)
		%> @fn [result, win, wasEvent] = checkTouchWindows(me, windows, panelType)
		%>
		%> @param windows - a touch rect to test (default use window)
		%> @param panelType 1 = front panel, 2 = back panel (need to reverse X)
		%> @return result - true / false
		% ===================================================================
			if ~exist('windows','var'); windows = []; end
			if ~exist('panelType','var') || isempty(panelType); panelType = 1; end

			nWindows = max([1 size(windows,1)]);
			result = false; win = 1; wasEvent = false; xy = [];

			event = getEvent(me);

			while ~isempty(event) && iscell(event); event = event{1}; end
			if isempty(event); return; end

			wasEvent = true; 
			
			if panelType == 2; event.MappedX = me.screenVals.width - event.MappedX; end

			xy = me.screen.toDegrees([event.MappedX event.MappedY]);
			event.xy = xy;
			if ~isempty(xy);
				if isempty(windows)
					result = calculateWindow(me, xy(1), xy(2));
				else
					for i = 1 : nWindows
						result(i,1) = calculateWindow(me, xy(1), xy(2), windows(i,:));
						if result(i,1); win = i; result = true; break;end
					end
				end
				event.result = result;
				me.event = event;
				me.x = xy(1); me.y = xy(2);
			end
		end

		% ===================================================================
		%> @fn isHold
		%>
		%> @param
		%> @return
		% ===================================================================
		function [held, heldtime, release, releasing, searching, failed, touch] = isHold(me)
			held = false; heldtime = false; release = false;
			releasing = false; searching = true; failed = false; touch = false;

			me.hold.now = GetSecs;
			if me.hold.start == 0
				me.hold.start = me.hold.now;
				me.hold.N = 0;
				me.hold.touched = false;
				me.hold.total = 0;
				me.hold.search = 0;
				me.hold.init = 0;
				me.hold.length = 0;
				me.hold.releaseinit = 0;
				me.hold.release = 0;
				me.wasHeld = false;
			else
				me.hold.total = me.hold.now - me.hold.start;
				if ~me.hold.touched
					me.hold.search = me.hold.total;
				end
			end

			[held, win, wasEvent] = checkTouchWindows(me);
			if ~wasEvent || isnan(held)
				if me.hold.N > 0
					me.hold.length = me.hold.now - me.hold.init;
				end
				return;
			else
				touch = true;
			end

			if held == -100
				me.wasNegation = true;
				searching = false;
				failed = true;
				if me.verbose; fprintf('--->>> touchManager -100 NEGATION!\n'); end
				return
			end

			if me.eventPressed && held #A
				me.hold.touched = true;
				searching = false;
				fprintf('A--->');
				if me.eventNew == true && me.hold.init == 0
					me.hold.init = me.hold.now;
					me.hold.N = me.hold.N + 1;
					me.hold.releaseinit = me.hold.init + me.window.hold;
					me.hold.length = 0;
				else
					me.hold.length = me.hold.now - me.hold.init;
				end
				if me.hold.length >= me.window.hold
					me.wasHeld = true;
					heldtime = true;
					releasing = true;
				end
				me.hold.release = me.hold.now - me.hold.releaseinit;
				if me.hold.release < me.window.release
					releasing = true;
				end
			elseif me.eventPressed && ~held #B
				fprintf('B--->');
				me.hold.touched = true;
				if me.hold.N > 0
					failed = true;
					searching = false;
				else
					searching = true;
				end
			elseif me.eventRelease && held #C
				searching = false;
				fprintf('C--->');
				me.hold.length = me.hold.now - me.hold.init;
				if me.hold.N > 0
					if me.hold.length >= me.window.hold
						me.wasHeld = true;
						heldtime = true;
						releasing = true;
					end
				end
				me.hold.release = me.hold.now - me.hold.releaseinit;
				if me.hold.release < me.window.release
					release = false;
				else
					release = true;
				end
			else #D
				fprintf('D--->');
				failed = true;
				searching = false;
			end
			me.isSearching = searching;
			me.isReleased = release;
			if true
				fprintf('%i n:%i mv:%i p:%i r:%i <%.1fX %.1fY> %.2f-tot %.2f-srch %.2f-hld %.2f-rel h:%i t:%i r:%i rl:%i s:%i f:%i N:%i\n',...
				me.eventID,me.eventNew,me.eventMove,me.eventPressed,me.eventRelease,me.x,me.y,me.hold.total,me.hold.search,me.hold.length,me.hold.release,held,heldtime,release,releasing,searching,failed,me.hold.N);
			end
		end


		% ===================================================================
		function [out, held, heldtime, release, releasing, searching, failed, touch] = testHold(me, yesString, noString)
		%> @fn testHold
		%>
		%> @param
		%> @return
		% ===================================================================
			[held, heldtime, release, releasing, searching, failed, touch] = isHold(me);
			out = '';
			if ~touch; return; end
			if failed || (~held && ~searching)
				out = noString;
			elseif held && heldtime
				out = yesString;
			end
		end

		% ===================================================================
		function [out, held, heldtime, release, releasing, searching, failed, touch] = testHoldRelease(me, yesString, noString)
		%> @fn testHoldRelease
		%>
		%> @param
		%> @return
		% ===================================================================
			[held, heldtime, release, releasing, searching, failed, touch] = isHold(me);
			out = '';
			if ~touch; return; end
			if failed || (held && heldtime && ~releasing)
				out = noString;
			elseif ~held && me.hold.N > 0 && ~me.wasHeld
				out = noString;
			elseif me.wasHeld && release
				out = yesString;
			end

		end

		% ===================================================================
		function demo(me)
		%> @fn demo
		%>
		%> @param
		%> @returnhld
		% ===================================================================
			if isempty(me.screen); me.screen = screenManager(); end
			sM = me.screen;
			windowed=[]; sf=[];
			if max(Screen('Screens'))==0; windowed = [0 0 1600 800]; end
			if ~isempty(windowed); sf = kPsychGUIWindow; end
			sM.windowed = windowed; sM.specialFlags = sf;
			oldWin = me.window;
			oldVerbose = me.verbose;
			me.verbose = true;

			if ~sM.isOpen; open(sM); end
			WaitSecs(2);
			setup(me, sM); 		%===================!!! Run setup first
			im = discStimulus('size', 5);
			setup(im, sM);

			quitKey = KbName('escape');
			doQuit = false;
			createQueue(me);	%===================!!! Create Queue
			start(me); 			%===================!!! Start touch collection
			try
				for i = 1 : 5
					if doQuit; break; end
					tx = randi(20)-10;
					ty = randi(20)-10;
					im.xPositionOut = tx;
					im.yPositionOut = ty;
					me.window.X = tx;
					me.window.Y = ty;
					me.window.radius = im.size/2;
					update(im);
					fprintf('\n\nTRIAL %i -- X = %i Y = %i R = %.2f\n',i,me.window.X,me.window.Y,me.window.radius);
					rect = toDegrees(sM, im.mvRect, 'rect');
					resetAll(me);
					flush(me); 	%===================!!! flush the queue
					txt = '';
					vbl = flip(sM); ts = vbl;
					result = 'timeout';
					while vbl <= ts + 20
						[r, hld, hldt, rel, reli, se, fl, tch] = testHold(me,'yes','no');
						if hld
							txt = sprintf('%s IN x = %.1f y = %.1f - h:%i ht:%i r:%i rl:%i s:%i f:%i touch:%i N:%i',r,me.x,me.y,hld,hldt,rel,reli,se,fl,tch,me.hold.N);
						elseif ~isempty(me.x)
							txt = sprintf('%s OUT x = %.1f y = %.1f - h:%i ht:%i r:%i rl:%i s:%i f:%i touch:%i N:%i',r,me.x,me.y,hld,hldt,rel,reli,se,fl,tch,me.hold.N);
						else
							txt = sprintf('%s NO touch - h:%i ht:%i r:%i rl:%i s:%i f:%i touch:%i N:%i',r,hld,hldt,rel,reli,se,fl,tch,me.hold.N);
						end
						drawBackground(sM);
						drawText(sM,txt); drawGrid(sM);
						if ~me.wasHeld; draw(im); end
						vbl = flip(sM);
						if strcmp(r,'yes')
							result = 'correct'; break;
						elseif strcmp(r,'no')
							result = 'incorrect'; break;
						end
						[pressed,~,keys] = octickaCore.getKeys([]);
						if pressed && any(keys(quitKey)); doQuit = true; break; end
					end
					drawTextNow(sM, result);
					fprintf('RESULT: %s - \n',result);
					disp(me.hold);
					WaitSecs(3);
				end
				stop(me); close(me); %===================!!! stop and close
				me.window = oldWin;
				me.verbose = oldVerbose;
				try reset(im); end
				try close(sM); end
			catch ME
				try reset(im); end
				try close(sM); end
				try close(me); end
				rethrow(ME);
			end
		end

	end

	%=======================================================================
	methods (Static = true) %------------------STATIC METHODS
	%=======================================================================

	end

	%=======================================================================
	methods (Access = protected) %------------------PROTECTED METHODS
	%=======================================================================

		% ===================================================================
		function [result, window] = calculateWindow(me, x, y, tempWindow)
		%> @fn setup
		%>
		%> @param
		%> @return
		% ===================================================================
			if exist('tempWindow','var') && isnumeric(tempWindow) && length(tempWindow) == 4
				pos = screenManager.rectToPos(tempWindow);
				radius = pos.radius;
				xWin = pos.X;
				yWin = pos.Y;
			else
				radius = me.window.radius;
				xWin = me.window.X;
				yWin = me.window.Y;
			end
			result = false; resultneg = false; match = false;
			window = false; windowneg = false;
			negradius = radius + me.negationBuffer;
			ez = me.exclusionZone;
			% ---- test for exclusion zones first
			if ~isempty(ez)
				for i = 1:size(ez,1)
					% [-x +x -y +y]
					if (x >= ez(i,1) && x <= ez(i,3)) && ...
						(y >= ez(i,2) && y <= ez(i,4))
						result = -100;
						return;
					end
				end
			end
			% ---- circular test
			if length(radius) == 1
				r = sqrt((x - xWin).^2 + (y - yWin).^2); %fprintf('X: %.1f-%.1f Y: %.1f-%.1f R: %.1f-%.1f\n',x, xWin, me.y, yWin, r, radius);
				window = find(r < radius);
				windowneg = find(r < negradius);
			else % ---- x y rectangular window test
				for i = 1:length(xWin)
					if (x >= (xWin - radius(1))) && (x <= (xWin + radius(1))) ...
							&& (y >= (yWin - radius(2))) && (y <= (yWin + radius(2)))
						window(i) = i;
						match = true;
					end
					if (x >= (xWin - negradius(1))) && (x <= (xWin + negradius(1))) ...
							&& (y >= (yWin - negradius(2))) && (y <= (yWin + negradius(2)))
						windowneg(i) = i;
					end
					if match == true; break; end
				end
			end
			me.win = window;
			if any(window); result = true;end
			if any(windowneg); resultneg = true; end
			if me.window.doNegation && resultneg == false
				result = -100;
			end
		end
	end
end
