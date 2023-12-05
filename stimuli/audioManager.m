classdef audioManager < octickaCore
	% AUDIOMANAGER Connects and manages audio playback, set as global aM from runExperiment.runTask()
	properties
		device			= []
		fileName		= ''
		mode			= 1
		numChannels		= 2
		frequency		= 44100
		lowLatency		= 0
		latencyLevel	= 0
		%> this allows us to be used even if no sound is attached
		silentMode		= false
		%> chain snd() function to use psychportaudio?
		chainSnd		= false
		verbose			= true
	end

	properties (SetAccess = protected, GetAccess = public)
		aHandle			= []
		devices			= []
		status			= []
		isBuffered		= false
		fileNames		= {};
		isSetup			= false
		isOpen			= false
		isSample		= false
	end

	properties (Access = protected)
		waves			= []
		handles			= []
		isFiles			= false
		allowedProperties = {'numChannels', 'frequency', 'lowLatency', ...
			'device', 'fileName', 'silentMode', 'verbose'}
	end

	%=======================================================================
	methods     %------------------PUBLIC METHODS--------------%
	%=======================================================================

		%==============CONSTRUCTOR============%
		function me = audioManager(varargin)

			args = octickaCore.addDefaults(varargin,struct('name','audio-manager'));
			me=me@octickaCore(args); %we call the superclass constructor first
			me.parseArgs(args, me.allowedProperties);

			isValid = checkFiles(me);
			if ~isValid
				me.logOutput('constructor','Please ensure valid file/dir name');
			end
			if ~isempty(me.device) && me.device < 0; me.silentMode = true; end
			getDevices(me);
			me.logOutput('constructor','Audio Manager initialisation complete');
		end

		% ===================================================================
		%> @brief open
		%>
		% ===================================================================
		function open(me)
			if me.silentMode || me.isOpen; return; end
			setup(me);
		end

		% ===================================================================
		%> @brief setup
		%>
		% ===================================================================
		function setup(me)
			if ~isempty(me.device) && me.device < 0; me.silentMode = true; end
			if me.silentMode || me.isOpen; return; end
			isValid = checkFiles(me);
			if ~isValid;disp('NO valid file/dir name, only beep() will work');end

			InitializePsychSound(me.lowLatency);
			try PsychPortAudio('Close'); end

			if me.lowLatency == 0; me.latencyLevel = 0; end

			makeWave(me,3000,0.2);
			makeWave(me,3000,0.5);
			makeWave(me,2000,0.2);
			makeWave(me,2000,0.5);
			makeWave(me,1000,0.2);
			makeWave(me,1000,0.5);
			makeWave(me,500,0.2);
			makeWave(me,500,0.5);
			makeWave(me,250,0.2);
			makeWave(me,250,0.2);

			if me.device > length(me.devices)
				fprintf('You have specified a non-existant device, trying first available device!\n');
				me.device = [];
				fprintf('Using device []\n');
			end
			try
				if isempty(me.aHandle)
					% PsychPortAudio('Open' [, deviceid][, mode][, reqlatencyclass][, freq]
					% [, channels][, buffersize][, suggestedLatency][, selectchannels]
					% [, specialFlags=0]);
					me.aHandle = PsychPortAudio('Open', me.device, me.mode, me.latencyLevel,...
						me.frequency, me.numChannels);
				end
				if me.chainSnd
					Snd('Open',me.aHandle); % chain Snd() to this instance
				end
				PsychPortAudio('Volume', me.aHandle, 1);
				me.status = PsychPortAudio('GetStatus', me.aHandle);
				me.frequency = me.status.SampleRate;
				me.silentMode = false;
				me.isSetup = true;
				me.isOpen = true;
			catch ME
				getReport(ME);
				me.reset();
				warning('--->audioManager: setup failed, going into silent mode, note you will have no sound!')
				me.silentMode = true;
			end
		end

		% ===================================================================
		%> @brief setup
		%>
		% ===================================================================
		function loadSamples(me)
			if me.silentMode; return; end
			if me.isFiles
				%TODO
			else
				[audiodata, ~] = psychwavread(me.fileName);
			end
			PsychPortAudio('FillBuffer', me.aHandle, audiodata');
			me.isSample = true;
		end

		% ===================================================================
		%> @brief
		%>
		% ===================================================================
		function play(me, when)
			if me.silentMode; return; end
			if ~exist('when','var'); when = []; end
			if ~me.isSetup; setup(me);end
			if ~me.isSample; loadSamples(me);end
			if me.isSetup && me.isSample
				PsychPortAudio('Start', me.aHandle, [], when);
			end
		end

		% ===================================================================
		%> @brief
		%>
		% ===================================================================
		function waitUntilStopped(me)
			if me.silentMode; return; end
			if me.isSetup
				PsychPortAudio('Stop', me.aHandle, 1, 1);
			end
		end

		% ===================================================================
		%> @brief
		%>
		% ===================================================================
		function beep(me,freq,durationSec,fVolume)
			if me.silentMode; return; end
			if ~me.isSetup; setup(me);end

			if ~exist('freq', 'var');freq = 2000;end
			if isnumeric(freq) && length(freq) == 3; fVolume = freq(3); durationSec=freq(2); freq = freq(1); end
			if ~exist('durationSec', 'var');durationSec = 0.2;	end
			if ~exist('fVolume', 'var'); fVolume = 0.2;
			else
				% Clamp if necessary
				if (fVolume > 1.0)
					fVolume = 1.0;
				elseif (fVolume < 0)
					fVolume = 0;
				end
			end
			if ischar(freq)
				if strcmpi(freq, 'high'); freq = 3000;
				elseif strcmpi(freq, 'med'); freq = 1000;
				elseif strcmpi(freq, 'medium'); freq = 1000;
				elseif strcmpi(freq, 'medlow'); freq = 500;
				elseif strcmpi(freq, 'low'); freq = 250;
				end
			end

			soundVec = makeWave(me,freq,durationSec);

			% Scale down the volume
			soundVec = soundVec * fVolume;
			PsychPortAudio('FillBuffer', me.aHandle, soundVec);
			PsychPortAudio('Start', me.aHandle);
		end

		% ===================================================================
		%> @brief
		%>
		% ===================================================================
		function run(me)
			setup(me)
			play(me);
			waitUntilStopped(me);
			reset(me);
		end

		% ===================================================================
		%> @brief Reset
		%>
		% ===================================================================
		function reset(me)
			try
				if ~isempty(me.aHandle)
					PsychPortAudio('Stop', me.aHandle, 0, 1);
				end
				try PsychPortAudio('DeleteBuffer'); end %#ok<*TRYNC>
				try
					PsychPortAudio('Close',me.aHandle);
				catch ME
					getReport(ME);
					PsychPortAudio('Close');
				end
				if isnan(me.device); me.device = []; end
				me.aHandle = [];
				me.status = [];
				me.waves = [];
				me.frequency = [];
				me.isSetup = false; me.isOpen = false; me.isSample = false;
				me.silentMode = false;
			catch ME
				getReport(ME);
				me.aHandle = [];
				me.status = [];
				me.frequency = [];
				me.isSetup = false; me.isOpen = false; me.isSample = false;
			end
			try InitializePsychSound(me.lowLatency); end
		end

		% ===================================================================
		%> @brief Close
		%>
		% ===================================================================
		function close(me)
			reset(me);
		end

		% ===================================================================
		%> @brief Close
		%>
		% ===================================================================
		function delete(me)
			reset(me);
		end

	end %---END PUBLIC METHODS---%

	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================

		% ===================================================================
		%> @brief makeWave
		%>
		% ===================================================================
		function wave = makeWave(me, freq, dur)
			f = num2str(freq);
			d = num2str(dur);
			if isempty(me.waves)
				me.waves = struct();
				me.waves.(f).(d) = [];
			end
			fn = fieldnames(me.waves);
			idx = find(strcmp(f,fn));
			if isempty(idx); me.waves.(f) = struct(); end
			fn2 = fieldnames(me.waves.(f));
			idx2 = find(strcmp(d,fn2));
			if isempty(idx2); me.waves.(f).(d) = []; end
			if ~isempty(idx) && ~isempty(idx2) && ~isempty(me.waves.(f).(d))
				wave = me.waves.(f).(d);
			else
				nSample = me.frequency*dur;
				wave = sin(2*pi*freq*(1:nSample)/me.frequency);
				wave = [wave;wave];
				me.waves.(f).(d) = wave;
			end
		end

		% ===================================================================
		%> @brief getDevices
		%>
		% ===================================================================
		function getDevices(me)
			try
				me.devices = PsychPortAudio('GetDevices');
			end
		end

		% ===================================================================
		%> @brief findFiles
		%>
		% ===================================================================
		function isValid = checkFiles(me)
			isValid = false;
			if isempty(me.fileName) || ~exist(me.fileName,'file')
				p = mfilename('fullpath');
				p = fileparts(p);
				me.fileName = [p filesep 'Coo2.wav'];
				me.fileNames{1} = me.fileName;
			elseif exist(me.fileName,'dir') == 7
				findFiles(me);
			end
			if exist(me.fileName,'file') || ~isempty(me.fileNames)
				isValid = true;
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
					if regexpi(e,'wav')
						n = n + 1;
						me.fileNames{n} = [me.fileName filesep f e];
					end
				end
			end
			if ~isempty(me.fileNames); me.isFiles = true; end
		end

	end %---END PROTECTED METHODS---%

	%=======================================================================
	methods ( Access = private ) %-------PRIVATE METHODS-----%
	%=======================================================================

	end %---END PRIVATE METHODS---%
end
