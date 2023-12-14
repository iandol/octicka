% ========================================================================
%> Copyright ©2014-2023 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef gpioManager < octickaCore
	properties
		%> board type
		board					= 'RPi'
		%> legacy, wiringpi, pigpio
		mode					= 'pigpiod'
		%> run with no gpio used, useful for debugging
		silentMode				= false
		%> output logging info
		verbose					= false
		%> parameters for use when giving rewards via fluid or food
		%> actuator, type = rpi
		reward					= struct('type', 'rpi', 'pin', 27, 'time', 250, 'controlPin', 17)
	end

  properties (Hidden = true)
		availablePins		= {}
		device					= []
		port					  = ''
  endproperties

	properties (Access = protected)
		allowedProperties = {'mode','board','reward','silentMode','verbose'}
	end

	methods%------------------PUBLIC METHODS--------------%

		%==============CONSTRUCTOR============%
		function me = gpioManager(varargin)
			% arduinoManager Construct an instance of this class
			args = octickaCore.addDefaults(varargin,struct('name','gpio manager'));
			me=me@octickaCore(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);
			reset(me);
		end

		%=======================================
		function giveReward(me)
			if me.silentMode; return; end
			try
				switch me.mode
				case 'pigpiod'
					RPiGPIOMex2(1, me.reward.pin, 1);
					WaitSecs('YieldSecs', me.reward.time/1e3);
					RPiGPIOMex2(1, me.reward.pin, 0);
				case 'wiringpi'
					RPiGPIOMex(1, me.reward.pin, 1);
					WaitSecs('YieldSecs', me.reward.time/1e3);
					RPiGPIOMex(1, me.reward.pin, 0);
				otherwise
					system(['raspi-gpio set ' num2str(me.reward.pin) ' dh']);
					WaitSecs('YieldSecs', me.reward.time/1e3);
					system(['raspi-gpio set ' num2str(me.reward.pin) ' dl']);
				end
			end
		end

		%=======================================
		function open(me)
			reset(me);
		end

		%=======================================
		function close(me)
			reset(me);
		end

		%=======================================
		function reset(me)
			s = exist('RPiGPIOMex', 'file');
			if s == 0 && strcmpi(me.mode,'wiringpi')
				fprintf('\nProblem with WiringPi, will try Pigpiod...\n');
				me.mode = 'pigpiod';
			end
			[~,ss] = system('pidof pigpiod');
			if isempty(ss) && strcmpi(me.mode,'pigpiod')
				fprintf('\nYou MUST run `sudo pigpiod` BEFORE using this function, switching to legacy mode\n');
				me.mode = 'legacy';
			end
			if me.silentMode; return; end
			if me.verbose
				fprintf('--->>> gpioManager: using %s mode -- pin %i @ %.2fms\n',me.mode,me.reward.pin,me.reward.time);
			end
			try
				switch me.mode
				case 'pigpiod'
					RPiGPIOMex2(3, me.reward.controlPin, 1); % set as output
					RPiGPIOMex2(1, me.reward.controlPin, 0);
					RPiGPIOMex2(3, me.reward.pin, 1); % set as output
					RPiGPIOMex2(1, me.reward.pin, 0);
				case 'wiringpi'
					RPiGPIOMex(3, me.reward.controlPin, 1); % set as output
					RPiGPIOMex(1, me.reward.controlPin, 0);
					RPiGPIOMex(3, me.reward.pin, 1); % set as output
					RPiGPIOMex(1, me.reward.pin, 0);
					if me.verbose
						[~,x]=system('gpio readall');
						disp(x);
					end
				otherwise
					system(['raspi-gpio set ' num2str(me.reward.controlPin) ' op']);
					system(['raspi-gpio set ' num2str(me.reward.pin) ' op']);
					system(['raspi-gpio set ' num2str(me.reward.controlPin) ' dl']);
					system(['raspi-gpio set ' num2str(me.reward.pin) ' dl']);
				end
			catch ME
				getReport(ME);
				me.silentMode = true; return;
			end
		end

	end % END METHODS

end % END CLASS
