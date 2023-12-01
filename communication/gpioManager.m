% ========================================================================
%> Copyright ©2014-2023 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef gpioManager < octickaCore
	properties
		%> board type
		board					= 'RPi'
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
		allowedProperties = {'reward','silentMode','verbose'}
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
				RPiGPIOMex(1, me.reward.pin, 1);
				WaitSecs('YieldSecs', me.reward.time/1e3);
				RPiGPIOMex(1, me.reward.pin, 0);
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
			s = exist('RPiGPIOMex', 'file')
			if s == 0
				me.silentMode = true;
			end
			if me.silentMode; return; end
			try
        RPiGPIOMex(3, me.reward.controlPin, 1); % set as output
        RPiGPIOMex(1, me.reward.controlPin, 0);
				RPiGPIOMex(3, me.reward.pin, 1); % set as output
        RPiGPIOMex(1, me.reward.pin, 0);
        if me.verbose
          [~,x]=system('gpio readall');
          disp(x);
        end
      catch ME
        getReport(ME);
        me.silentMode = true; return;
			end
		end

	end % END METHODS

end % END CLASS
