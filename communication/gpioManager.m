% ========================================================================
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef gpioManager < octickaCore
	properties
		%> board type
		board					= 'RPi'
		%> run with no arduino attached, useful for debugging
		silentMode				= false
		%> output logging info
		verbose					= false
		%> parameters for use when giving rewards via fluid or food
		%> actuator, type = TTL / fluid / food / rpi
		reward					= struct('type', 'TTL', 'pin', 27, 'time', 250)
		%> specify the available pins to use; 2-13 is the default for an Uno
		%> 0-10 for the xiao (though xiao pins 11-14 can control LEDS)
		availablePins			= {}
		%> the arduinoIOPort device object, you can call the methods
		%> directly if required.
		device					= []
		%> arduino port, if left empty it will make a guess during open()
		port					= ''
	end

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

		function giveReward(me)
			if me.silentMode; return; end
			try
				system(['raspi-gpio set ' num2str(me.reward.pin) ' dh']);
				WaitSecs(me.reward.time);
				system(['raspi-gpio set ' num2str(me.reward.pin) ' dl']);
			end
		end

		function open(me)
			reset(me)
		end

		function close(me)

		end

		function reset(me)
			s = system('which raspi-gpio');
			if s ~= 0
				me.silentMode = true;
			end
			if me.silentMode; return; end
			try
				system('raspi-gpio set 17 op');
				system(['raspi-gpio set ' num2str(me.reward.pin) ' op']);
				system('raspi-gpio set 17 dl');
				system(['raspi-gpio set ' num2str(me.reward.pin) ' dl']);
			end
		end

	end

end