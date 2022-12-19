classdef touchManager < octickaCore
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here

	%--------------------PUBLIC PROPERTIES----------%
	properties
		device			= 1
		verbose			= false
		isDummy			= false
		window			= struct('X',0,'Y',0,'radius',[5]);
		nSlots			= 1e5
	end

	properties (SetAccess=private, GetAccess=public)
		devices			= []
		names			= []
		allInfo			= []
		x				= -1
		y				= -1
		isOpen			= false
		isQueue			= false
	end	

	properties (Access = private)
		ppd				= 36
		screen			= []
		win				= []
		screenVals		= []
		allowedProperties	= {'isDummy','device','verbose','window','nSlots'}
	end

	%=======================================================================
	methods %------------------PUBLIC METHODS
		%=======================================================================

		% ===================================================================
		function me = touchManager(varargin)
			%> @fn touchManagerx = []; y = [];t ouched = false;
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
			try [me.devices,me.names,me.allInfo] = GetTouchDeviceIndices([], 1); end
		end

		%================SET UP TOUCH INPUT============
		function  setup(me, sM)
			if isa(sM,'screenManager') && sM.isOpen
				me.screen = sM;
				me.win = sM.win; 
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
				fprintf('--->touchManager: %s\n',me.comment);
			elseif length(me.devices)==1
				me.comment = 'found ONE Touch Screen...';
				fprintf('--->touchManager: %s\n',me.comment);
			elseif length(me.devices)==2
				me.comment = 'found TWO Touch Screens plugged...';
				fprintf('--->touchManager: %s\n',me.comment);
			end
		end

		%================SET UP TOUCH INPUT============
		function createQueue(me, choice)
			if me.isDummy; return; end
			if ~exist('choice','var') || isempty(choice)
				choice = me.device;
			end
			for i = 1:length(choice)
				TouchQueueCreate(me.win, me.devices(choice(i)), me.nSlots);
			end
			me.isQueue = true;
			if me.verbose;me.logEvent('createQueue','Opened');end
		end

		%===============START=========
		function start(me, choice)
			if me.isDummy; return; end
			if ~exist('choice','var') || isempty(choice)
				choice=me.device;
			end
			if ~me.isQueue; createQueue(me,choice); end
			for i = 1:length(choice)
				TouchQueueStart(me.devices(choice(i)));
			end
			me.isOpen = true;
			if me.verbose;me.logEvent('start','Started queue');end
		end

		%===============FLUSH=========
		function flush(me, choice)
			if me.isDummy; return; end
			if ~exist('choice','var') || isempty(choice)
				choice = me.device;
			end
			for i = 1:length(choice)
				TouchEventFlush(me.devices(choice(i)));
			end
		end

		%===========EVENT AVAIL=========
		function navail = eventAvail(me, choice)
			navail = [];
			if me.isDummy
				[x,y,b] = GetMouse;
				if any(b); navail = true; end
				return
			end
			if ~exist('choice','var') || isempty(choice);choice=me.device;end
			for i = 1:length(choice)
				navail(i)=TouchEventAvail(me.devices(choice(i))); %#ok<*AGROW> 
			end
		end

		%===========GETEVENT=========
		function event = getEvent(me, choice)
			event = {};
			if me.isDummy
				[x,y,b] = GetMouse(me.win);
				if any(b)
					event{1} = struct('Type',2,'Time',GetSecs,...
					'X',x,'Y',y,'ButtonStates',b,...
					'NormX',x/me.screenVals.width,'NormY',y/me.screenVals.height);
				end
				return;
			end
			if ~exist('choice','var') || isempty(choice)
				choice=me.device;
			end
			for i = 1:length(choice)
				event{i} = TouchEventGet(me.devices(choice(i)), me.win);
			end
		end
		
		%===========GETEVENT=========
		function [result, x, y] = checkTouchWindow(me, choice)
			result = false; x = []; y = [];
			if me.isDummy
				event = getEvent(me);
				if isempty(event); return; end
				while iscell(event);event = event{1}; end
				if isempty(event); return; end
				xy = me.screen.toDegrees([event.X event.Y]);
				x = xy(1); y = xy(2);
				if me.verbose;fprintf('dummy touch: %i %.2f %i %.2f\n',event.X, x, event.Y, y);end
				result = calculateWindow(me, x, y);
			else
				if ~exist('choice','var') || isempty(choice);choice=me.device;end
				if ~isempty(eventAvail(me,choice))
					event = getEvent(me);
					if isempty(event); return; end
					while iscell(event);event = event{1}; end
					if isempty(event); return; end
					xy = me.screen.toDegrees([event.X event.Y]);
					x = xy(1); y = xy(2);
					if me.verbose;fprintf('touch: %i %.2f %i %.2f\n',event.X, x, event.Y, y);end
					result = calculateWindow(me, x, y);
				end
			end
		end

		%===========CLOSE=========
		function close(me)
			me.isOpen = false;
			me.isQueue = false;
			if me.isDummy
				logOutput(me,'Closing dummy touchManager...');
			else
				for i = 1:length(me.device)
					TouchQueueStop(me.devices(me.device(i)));
				end
				logOutput(me,'Closing touchManager...');
			end
		end

	end

	methods (Access = protected)
		%===========calculateWindow=========
		function result = calculateWindow(me, x, y)
			result = false; window = false;
			% ---- test for exclusion zones first
			if ~isempty(me.exclusionZone)
				for i = 1:size(me.exclusionZone,1)
					% [-x +x -y +y]
					if (x >= me.exclusionZone(i,1) && x <= me.exclusionZone(i,2)) && ...
						(me.y >= me.exclusionZone(i,3) && me.y <= me.exclusionZone(i,4))
						result = -100;
						return;
					end
				end
			end
			% ---- circular test
			if length(me.window.radius) == 1 
				r = sqrt((x - me.window.X).^2 + (y - me.window.Y).^2); %fprintf('x: %g-%g y: %g-%g r: %g-%g\n',x, me.window.X, me.y, me.window.Y,r,me.window.radius);
				window = find(r < me.window.radius);
			else % ---- x y rectangular window test
				for i = 1:length(me.window.X)
					if (x >= (me.window.X - me.window.radius(1))) && (x <= (me.window.X + me.window.radius(1))) ...
							&& (me.y >= (me.window.Y - me.window.radius(2))) && (me.y <= (me.window.Y + me.window.radius(2)))
						window = i;
						break;
					end
				end
			end
			if any(window); result = true;end
		end
	end
end