% ========================================================================
%> @brief Arduino Manager > Connects and manages arduino communication. By
%> default it connects using arduinoIOPort (much faster than the MATLAB
%> serial port interface) and the adio.ino arduino sketch (the legacy
%> arduino interface by Mathworks), which provide much better performance
%> than MATLAB's current hardware package.
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef arduinoManager < octickaCore
	% ARDUINOMANAGER Connects and manages arduino communication. By default it
	% connects using arduinoIOPort and the adio.ino arduino sketch (the legacy
	% arduino interface by Mathworks), which provide much better performance
	% than MATLAB's hardware package.
	properties
		%> arduino port, if left empty it will make a guess during open()
		port 			= ''
		%> board type; uno [default] is a generic arduino, xiao is the seeduino xiao
		board			= 'Uno' 
		%> run with no arduino attached, useful for debugging
		silentMode		= false
		%> output logging info
		verbose			= false
		%> open a GUI to drive a reward directly
		openGUI			= false
		%> which pin to trigger the reward TTL by default?
		rewardPin		= 2
		%> time of the TTL sent by default?
		rewardTime		= 300
		%> specify the available pins to use; 2-13 is the default for an Uno
		%> 0-10 for the xiao (though xiao pins 11-14 can control LEDS)
		availablePins	= {2,3,4,5,6,7,8,9,10,11,12,13}
		%> the arduinoIOPort device object, you can call the methods
		%> directly if required.
		device			= []
		%> for the stepper specify the delay between digital writes
		delaylength		= 0.03;
	end
	properties (SetAccess = private, GetAccess = public)
		%> which ports are available
		ports			= []
		%> could we succesfully open the arduino?
		isOpen			= false
		%> ID from device
		deviceID		= ''
	end
	properties (SetAccess = private, GetAccess = private, Transient = true)
		%> a screen object to bind to
		screen			= []
	end
	properties (SetAccess = private, GetAccess = private)
		allowedProperties = {'availablePins','rewardPin','rewardTime','board',...
			'port','silentMode','verbose'}
	end
	
	methods%------------------PUBLIC METHODS--------------%
		
		%==============CONSTRUCTOR============%
		function me = arduinoManager(varargin)
		% arduinoManager Construct an instance of this class
			args = octickaCore.addDefaults(varargin,struct('name','arduino manager'));
			me=me@octickaCore(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);
			if isempty(me.port)
				checkPorts(me);
				if ~isempty(me.ports)
					fprintf('--->arduinoManager: Ports available: %s\n',disp(me.ports));
					if isempty(me.port); me.port = char(me.ports{end}); end
				else
					me.comment = 'No Serial Ports are available, going into silent mode';
					fprintf('--->arduinoManager: %s\n',me.comment);
					me.silentMode = true;
				end
			end
			if ~exist('arduinoIOPort','file')
				me.comment = 'Cannot find arduinoIOPort, check octicka path!';
				warning(me.comment)
				me.silentMode = true;
			end
		end
		
		%===============OPEN DEVICE================%
		function open(me)
			if me.isOpen || ~isempty(me.device);disp('-->arduinoManager: Already open!');return;end
			if me.silentMode;disp('-->arduinoManager: In silent mode, try to close() then open()!');me.isOpen=false;return;end
			if isempty(me.port);warning('--->arduinoManager: Better specify the port to use; will try to select one from available ports!');return;end
			close(me); checkPorts(me);
			try
				if IsWin && ~isempty(regexp(me.port, '^/dev/', 'once'))
					warning('--->arduinoManager: Linux/macOS port specified but running on windows!')
					me.port = '';
				elseif (IsLinux||IsOSX) && ~isempty(regexp(me.port, '^COM', 'once'))
					warning('--->arduinoManager: Windows port specified but running on Linux/macOS!')
					me.port = '';
				end
				if isempty(me.board)
					me.board = 'Uno';
				end
				switch me.board
					case {'Xiao','xiao'}
						if isempty(me.availablePins);me.availablePins = {0,1,2,3,4,5,6,7,8,9,10,11,12,13};end
					otherwise
						if isempty(me.availablePins);me.availablePins = {2,3,4,5,6,7,8,9,10,11,12,13};end
				end
				endPin = max(cell2mat(me.availablePins));
				startPin = min(cell2mat(me.availablePins));
				
				try
					me.device = arduinoIOPort(me.port,endPin,startPin);
				catch
					me.device.isDemo = true;
				end
				
				if me.device.isDemo
					me.isOpen = false; me.silentMode = true;
					warning('--->arduinoManager: IOport couldn''t open the port, going into silent mode!');
					return
				else
					me.deviceID = me.port;
					me.isOpen = true;
				end
				me.silentMode = false;
			catch ME
				me.silentMode = true; me.isOpen = false;
				fprintf('\n\n!!!Couldn''t open Arduino!!!\n');
				rethrow(ME);
			end
		end

		%===============CLOSE DEVICE================%
		function close(me)
			try me.device = []; end %#ok<*TRYNC> 
			try close(me.handles.parent); me.handles=[];end
			try me.deviceID = ''; end
			try me.availablePins = ''; end
			me.isOpen = false;
			me.silentMode = false;
			checkPorts(me);
		end
		
		%===============RESET================%
		function reset(me)
			try close(me); end
			me.silentMode = false;
			notinlist = true;
			if ~isempty(me.ports)
				for i = 1:length(me.ports)
					if strcmpi(me.port,me.ports{i})
						notinlist = false;
					end
				end
			end
			if notinlist && ~isempty(me.ports)
				me.port = me.ports{end};
			end
		end
		
		%===============PIN MODE================%
		function pinMode(me, line, mode)
			if ~me.isOpen || me.silentMode; return; end
			if nargin == 3
				pinMode(me.device, line, mode);
			elseif nargin == 2
				pinMode(me.device, line);
			else
				pinMode(me.device)
			end
		end
		
		%===============ANALOG READ================%
		function value = analogRead(me, line)
			if ~me.isOpen || me.silentMode; return; end
			if ~exist('line','var') || isempty(line); line = me.rewardPin; end
			value = analogRead(me.device, line);
			if me.verbose;fprintf('===>>> ANALOGREAD: pin %i = %i \n',line,value);end
		end

		%===============ANALOG WRITE================%
		function analogWrite(me, line, value)
			if ~me.isOpen || me.silentMode; return; end
			if ~exist('line','var') || isempty(line); line = me.rewardPin; end
			if ~exist('value','var') || isempty(value); value = 128; end
			analogWrite(me.device, line, value);
			if me.verbose;fprintf('===>>> ANALOGWRITE: pin %i = %i \n',line,value);end
		end

		%===============DIGITAL READ================%
		function value = digitalRead(me, line)
			if ~me.isOpen || me.silentMode; return; end
			if ~exist('line','var') || isempty(line); line = me.rewardPin; end
			value = digitalRead(me.device, line);
			if me.verbose;fprintf('===>>> DIGREAD: pin %i = %i \n',line,value);end
		end
		
		%===============DIGITAL WRITE================%
		function digitalWrite(me, line, value)
			if ~me.isOpen || me.silentMode; return; end
			if ~exist('line','var') || isempty(line); line = me.rewardPin; end
			if ~exist('value','var') || isempty(value); value = 0; end
			digitalWrite(me.device, line, value);
			if me.verbose;fprintf('===>>> DIGWRITE: pin %i = %i \n',line,value);end
		end
		
		%===============SEND TTL (legacy)================%
		function sendTTL(me, line, time)
			timedTTL(me, line, time)
		end
		
		%===============TIMED TTL================%
		function timedTTL(me, line, time)
			if ~me.isOpen; return; end
			if ~me.silentMode
				if ~exist('line','var') || isempty(line); line = me.rewardPin; end
				if ~exist('time','var') || isempty(time); time = me.rewardTime; end
				timedTTL(me.device, line, time);
				if me.verbose;fprintf('===>>> timedTTL: TTL pin %i for %i ms\n',line,time);end
			else
				if me.verbose;fprintf('===>>> timedTTL: Silent Mode\n');end
			end
		end
		
		%===============STROBED WORD================%
		function strobeWord(me, value)
			if ~me.isOpen; return; end
			if ~me.silentMode
				strobeWord(me.device, value);
				if me.verbose;fprintf('===>>> STROBED WORD: %i sent to pins 2-8\n',value);end
			end
		end
		
		%===============TIMED DOUBLE TTL================%
		function timedDoubleTTL(me, line, time)
			if ~me.silentMode
				if ~exist('line','var') || isempty(line); line = me.rewardPin; end
				if ~exist('time','var') || isempty(time); time = me.rewardTime; end
				if time < 0; time = 0;end
				timedTTL(me.device, line, 10);
				WaitSecs('Yieldsecs',time/1e3);
				timedTTL(me.device, line, 10);
				if me.verbose;fprintf('===>>> timedTTL: double TTL pin %i for %i ms\n',line,time);end
			else
				if me.verbose;fprintf('===>>> timedTTL: Silent Mode\n');end
			end
		end
		
		%===============TEST TTL================%
		function test(me,line)
			if me.silentMode || isempty(me.device); return; end
			if ~exist('line','var') || isempty(line); line = 2; end
			digitalWrite(me.device, line, 0);
			for ii = 1:20
				digitalWrite(me.device, line, mod(ii,2));
			end
		end
		
		%==================DRIVE STEPPER MOTOR============%
		function stepper(me,ndegree)
			ncycle      = floor(ndegree/(1.8*4));
			nstep       = round((rem(ndegree,(1.8*4))/7.2)*4);

			for i=1:ncycle
				cycleStepper(me)
			end
			switch nstep
				case 1
					me.digitalWrite(9, 0);    %//ENABLE CH A
					me.digitalWrite(8, 1);    %//DISABLE CH B
					me.digitalWrite(12,1);   %//Sets direction of CH A
					me.digitalWrite(3, 1);    %//Moves CH A
					WaitSecs('YieldSecs',me.delaylength);
				case 2
					me.digitalWrite(9, 0);    %//ENABLE CH A
					me.digitalWrite(8, 1);    %//DISABLE CH B
					me.digitalWrite(12,1);   %//Sets direction of CH A
					me.digitalWrite(3, 1);    %//Moves CH A
					WaitSecs('YieldSecs',me.delaylength);

					me.digitalWrite(9, 1);    %//DISABLE CH A
					me.digitalWrite(8, 0);    %//ENABLE CH B
					me.digitalWrite(13,0);   %//Sets direction of CH B
					me.digitalWrite(11,1);   %//Moves CH B
					WaitSecs('YieldSecs',me.delaylength);
				case 3
					me.digitalWrite(9, 0);    %//ENABLE CH A
					me.digitalWrite(8, 1);    %//DISABLE CH B
					me.digitalWrite(12,1);   %//Sets direction of CH A
					me.digitalWrite(3, 1);    %//Moves CH A
					WaitSecs('YieldSecs',me.delaylength);

					me.digitalWrite(9, 1);    %//DISABLE CH A
					me.digitalWrite(8, 0);    %//ENABLE CH B
					me.digitalWrite(13,0);   %//Sets direction of CH B
					me.digitalWrite(11,1);   %//Moves CH B
					WaitSecs('YieldSecs',me.delaylength);

					me.digitalWrite(9, 0);     %//ENABLE CH A-
					me.digitalWrite(8, 1);     %//DISABLE CH B
					me.digitalWrite(12,0);    %//Sets direction of CH A
					me.digitalWrite(3, 1);     %//Moves CH A
					WaitSecs('YieldSecs',me.delaylength);
				case 4
					cycleStepper(me)
			end
			stopStepper(me)
		end
		
		%================STEPPER CYCLR==========
		function  cycleStepper(me)
			me.digitalWrite(9, 0);    %//ENABLE CH A
			me.digitalWrite(8, 1);    %//DISABLE CH B
			me.digitalWrite(12,1);   %//Sets direction of CH A
			me.digitalWrite(3, 1);    %//Moves CH A
			WaitSecs('YieldSecs',me.delaylength);

			me.digitalWrite(9, 1);    %//DISABLE CH A
			me.digitalWrite(8, 0);    %//ENABLE CH B
			me.digitalWrite(13,0);   %//Sets direction of CH B
			me.digitalWrite(11,1);   %//Moves CH B
			WaitSecs('YieldSecs',me.delaylength);

			me.digitalWrite(9, 0);     %//ENABLE CH A-
			me.digitalWrite(8, 1);     %//DISABLE CH B
			me.digitalWrite(12,0);    %//Sets direction of CH A
			me.digitalWrite(3, 1);     %//Moves CH A
			WaitSecs('YieldSecs',me.delaylength);

			me.digitalWrite(9, 1);   %//DISABLE CH A
			me.digitalWrite(8, 0);   %//ENABLE CH B-
			me.digitalWrite(13,1);  %//Sets direction of CH B
			me.digitalWrite(11,1);  %//Moves CH B
			WaitSecs('YieldSecs',me.delaylength);
		end
		
		%================STOP STEPPER================
		function stopStepper(me)
			me.digitalWrite(9,1);        %//DISABLE CH A
			me.digitalWrite(3, 0);       %//stop Move CH A
			me.digitalWrite(8,1);        %//DISABLE CH B
			me.digitalWrite(11,0);      %//stop Move CH B
			WaitSecs('YieldSecs',me.delaylength);
		end
		
		%===========Check Ports==========%
		function checkPorts(me)
			if IsOctave
				if ~exist('serialportlist','file'); try pkg load instrument-control; end; end
				if ~verLessThan('instrument-control','0.7')
					me.ports = serialportlist('available');
				else
					me.ports = [];
				end
			else
				if ~verLessThan('matlab','9.7')	% use the nice serialport list command
					me.ports = serialportlist('available');
				else
					me.ports = seriallist; %#ok<SERLL> 
				end
			end
		end
			
		%===========Delete Method==========%
		function delete(me)
			fprintf('arduinoManager: closing connection if open...\n');
			try me.close; end
		end
	end
	
	methods ( Access = private ) %----------PRIVATE METHODS---------%
		
		%===========setLow Method==========%
		function setLow(me)
			if me.silentMode || ~me.isOpen; return; end
			for i = me.availablePins{1} : me.availablePins{end}
				me.device.pinMode(i,'output');
				me.device.digitalWrite(i,0);
			end
		end

		%===========setHigh Method==========%
		function setHigh(me)
			if me.silentMode || ~me.isOpen; return; end
			for i = me.availablePins{1} : me.availablePins{end}
				me.device.pinMode(i,'output');
				me.device.digitalWrite(i,0);
			end
		end
		
	end
	
end