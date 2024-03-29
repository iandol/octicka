% ========================================================================
classdef octickaCore < handle
%> @class octickaCore
%> @brief octickaCore base class inherited by other octicka classes.
%>
%> @section intro Introduction
%>
%> octickaCore is itself derived from handle. It provides methods to find
%> attributes with specific parameters (used in autogenerating UI panels),
%> clone the object, parse arguments safely on construction and add default
%> properties such as paths, dateStamp, uuid and name/comment management.
%>
%> Copyright ©2014-2023 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================

	%--------------------PUBLIC PROPERTIES----------%
	properties
		%> object name
		name  = ''
		%> comment
		comment  = ''
		verbose = false
	end

	%--------------------HIDDEN PROPERTIES------------%
	properties (SetAccess = protected, Hidden = true)
		%> are we cloning this from another object
		cloning  = false
	end

	%--------------------VISIBLE PROPERTIES-----------%
	properties (SetAccess = protected, GetAccess = public)
		%> clock() dateStamp set on construction
		dateStamp = []
		%> universal ID
		uuid = ''
		%> storage of various paths
		paths = []
	end

	%--------------------DEPENDENT PROPERTIES----------%
	properties (Dependent = true)
		%> The fullName is the object name combined with its uuid and class name
		fullName
	end

	%--------------------TRANSIENT PROPERTIES----------%
	properties (Access = protected, Transient = true)
		%> Octave version number, this is transient so it is not saved
		oversion  = 0
		%> sans font
		sansFont		= 'Ubuntu'
		%> monoFont
		monoFont		= 'Ubunto Mono'
	end

	%--------------------PROTECTED PROPERTIES----------%
	properties (Access = protected)
		%> class name
		className = ''
		%> save prefix generated from clock time
		savePrefix = ''
		%> cached full name
		fullName_ = ''
	end

	%--------------------PRIVATE PROPERTIES----------%
	properties (Access = private)
		%> allowed properties passed to object upon construction
		allowedPropertiesCore = {'name','comment','cloning'}
	end

	%=======================================================================
	methods %------------------PUBLIC METHODS
	%=======================================================================

		% ===================================================================
		function me = octickaCore(varargin)
		%> @fn octickaCore
		%> @brief Class constructor
		%>
		%> The class constructor for octickaCore.
		%>
		%> @param args are passed as name-value pairs or a structure of properties
		%> which is parsed.
		%>
		%> @return instance of class.
		% ===================================================================
			args = octickaCore.addDefaults(varargin);
			me.parseArgs(args, me.allowedPropertiesCore);
			warning ("off", "Octave:language-extension");
			me.dateStamp = clock();
			me.className = class(me);
			me.uuid = num2str(dec2hex(floor((now - floor(now))*1e10))); %me.uuid = char(java.util.UUID.randomUUID)%128bit uuid
			me.fullName = [me.name '<' me.uuid '>'];
			me.fullName_ = me.fullName;
			me.oversion = str2double(regexp(version,'^\d\.\d+','match','once'));
			setPaths(me);
			getFonts(me);
		end

		% ===================================================================
		function name = get.fullName(me)
		%> @fn get.fullName
		%> @brief concatenate the name with a uuid at get.
		%> @param
		%> @return name the concatenated name
		% ===================================================================
			if isempty(me.name)
				me.fullName_ = sprintf('%s#%s', me.className, me.uuid);
			else
				me.fullName_ = sprintf('%s<%s#%s>', me.name, me.className, me.uuid);
			end
			name = me.fullName_;
		end

		% ===================================================================
		function c = initialiseSaveFile(me, path)
		%> @fn initialiseSaveFile(me, path)
		%> @brief Initialise Save Dir
		%>
		%> @param path - the path to use.
		% ===================================================================
			if exist('path','var') && exist(path,"dir")
				me.paths.savedData = path;
			end
			c = fix(clock); %#ok<*CLOCK> compatible with octave
			c = num2str(c(1:6));
			c = regexprep(c,' +','-');
			me.savePrefix = c;
		end

		% ===================================================================
		function editProperties(me, props)
		%> @fn editProperties
		%> @brief method to modify a set of properties
		%>
		%> @param properties - cell or struct of properties to modify
		% ===================================================================
			me.addArgs(props);
		end

		% ===================================================================
		function setProp(me, property, value)
		%> @fn setProp(me, property, value)
		%> @brief method to fast change a particular value. This is
		%> useful for use in anonymous functions, like in the state machine.
		%>
		%> @param property — the property to change
		%> @param value — the value to change it to
		% ===================================================================
			if isprop(me,property)
				me.(property) = value;
			end
		end

		% ===================================================================
		function [rM, aM] = initialiseGlobals(me, doReset, doOpen)
		%> @fn [rM, aM] = initialiseGlobals(me)
		%> @brief we try no to use globals but for reward and audio, due to
		%> e.g. eyelink we can't help it, set them up here
		%>
		%> @param doReset - try to reset the object?
		%> @param doOpen  - try to open the object?
		% ===================================================================
			global rM aM

			if ~exist('doReset','var'); doReset = false; end
			if ~exist('doOpen','var'); doOpen = false; end

			%------initialise the rewardManager global object
			if ~isa(rM,'arduinoManager'); rM = arduinoManager(); end
			if rM.isOpen && doReset
				try rM.close; rM.reset; end
			end
			if doOpen && ~rM.isOpen; open(rM); end

			%------initialise an audioManager for beeps,playing sounds etc.
			if ~isa(aM,'audioManager'); aM = audioManager(); end
			if doReset
				try
					aM.silentMode = false;
					reset(aM);
				catch
					warning('Could not reset audio manager!');
					aM.silentMode = true;
				end
			end
			if doOpen && ~aM.isOpen && ~aM.silentMode
				open(aM);
				aM.beep(2000,0.1,0.1);
			end
		end

	end

	%=======================================================================
	methods ( Hidden = true ) %-------HIDDEN METHODS-----%
	%=======================================================================

		% ===================================================================
		function checkPaths(me)
		%> @fn checkPaths
		%> @brief checks the paths are valid
		%>
		% ===================================================================
			samePath = false;
			if isprop(me,'dir')

				%if our object wraps a plxReader, try to use its paths
				if isprop(me,'p') && isa(me.p,'plxReader')
					checkPaths(me.p);
					me.dir = me.p.dir; %inherit the path
				end

				if isprop(me,'matdir') %normally they are the same
					if ~isempty(me.dir) && strcmpi(me.dir, me.matdir)
						samePath = true;
					end
				end

				if ~exist(me.dir,'dir')
					if isprop(me,'file')
						fn = me.file;
					else
						fn = '';
					end
					fprintf('Please find new directory for: %s\n',fn);
					p = uigetdir('',['Please find new directory for: ' fn]);
					if p ~= 0
						me.dir = p;

					else
						warning('Can''t find valid source directory');
					end
				end
			end
			if isprop(me,'matdir')
				if samePath; me.matdir = me.dir; return; end
				if ~exist(me.matdir,'dir')
					if exist(me.dir,'dir')
						me.matdir = me.file;
					else
						if isprop(me,'matfile')
							fn = me.matfile;
						else
							fn = '';
						end
						fprintf('Please find new directory for: %s\n',fn);
						p = uigetdir('',['Please find new directory for: ' fn]);
						if p ~= 0
							me.matdir = p;
						else
							warning('Can''t find valid source directory');
						end
					end
				end
			end
			if isa(me,'plxReader')
				if isprop(me,'eA') && isa(me.eA,'eyelinkAnalysis')
					me.eA.dir = me.dir;
				end
			end
		end
	end

	%=======================================================================
	methods ( Static = true ) %-------STATIC METHODS-----%
	%=======================================================================

		% ===================================================================
		function args = makeArgs(args)
		%> @fn makeArgs
		%> @brief Converts cell args to structure array
		%>
		%>
		%> @param args input data
		%> @return args as a structure
		% ===================================================================
			if isstruct(args); return; end
			while iscell(args) && length(args) == 1
				args = args{1};
			end
			if iscell(args)
				if mod(length(args),2) == 1 % odd
					args = args(1:end-1); %remove last arg
				end
				odd = logical(mod(1:length(args),2));
				even = logical(abs(odd-1));
				args = cell2struct(args(even),args(odd),2);
			elseif isstruct(args)
				return
			else
				error('---> makeArgs: You need to pass name:value pairs / structure of name:value fields!');
			end
		end

		% ===================================================================
		function args = addDefaults(args, defs)
		%> @fn addDefaults
		%> @brief add default options to arg input
		%>
		%>
		%> @param args input structure from varargin
		%> @param defs extra default settings
		%> @return args structure
		% ===================================================================
			if ~exist('args','var'); args = struct; end
			if ~exist('defs','var'); defs = struct; end
			if iscell(args); args = octickaCore.makeArgs(args); end
			if iscell(defs); defs = octickaCore.makeArgs(defs); end
			fnameDef = fieldnames(defs); %find our argument names
			fnameArg = fieldnames(args); %find our argument names
			for i=1:length(fnameDef)
				id=cell2mat(cellfun(@(c) strcmp(c,fnameDef{i}),fnameArg,'UniformOutput',false));
				if ~any(id)
					args.(fnameDef{i}) = defs.(fnameDef{i});
				end
			end
		end

		% ===================================================================
		function result = hasKey(in, key)
		%> @fn hasKey
		%> @brief check if a struct / object has a propery / field
		%>
		%> @param value name
		% ===================================================================
			result = false;
			if isfield(in, key) || isprop(in, key)
				result = true;
			end
		end

		% ===================================================================
		function [pressed, name, keys] = getKeys(device)
		%> @fn getKeys
		%> @brief PTB Get key presses, stops key bouncing
		% ===================================================================
			persistent oldKeys
			if ~exist('device','var'); device = []; end
			if isempty(oldKeys); oldKeys = zeros(1,256); end
			pressed = false; name = []; keys = [];

			[press, ~, keyCode] = KbCheck(device);

			if press
				keys = keyCode & ~oldKeys;
				if any(keys)
					name = KbName(keys);
					pressed = true;
				end
			end
			oldKeys = keyCode;
		end

	end %--------END STATIC METHODS

	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================

		% ===================================================================
		function parseArgs(me, args, allowedProperties)
		%> @fn parseArgs
		%> @brief Sets properties from a structure or normal arguments pairs,
		%> ignores invalid or non-allowed properties
		%>
		%> @param args input structure
		%> @param allowedProperties properties possible to set on construction
		% ===================================================================
			if ischar(allowedProperties)
				%we used | for regexp but better use cell array
				allowedProperties = strsplit(allowedProperties,'|');
			end

			args = octickaCore.makeArgs(args);

			if isstruct(args)
				fnames = fieldnames(args); %find our argument names
				for i=1:length(fnames)
					if ismember(fnames{i},allowedProperties) %only set if allowed property
						me.logOutput(fnames{i},sprintf('Parsing: old = %s | New = %s', class(me.(fnames{i})), class(args.(fnames{i}))));
						try
							me.(fnames{i})=args.(fnames{i}); %we set up the properies from the arguments as a structure
						catch
							me.logOutput(fnames{i},'Propery invalid!',true);
						end
					end
				end
			end

		end

		% ===================================================================
		function addArgs(me, args)
		%> @brief Sets properties from a structure or normal arguments pairs,
		%> ignores invalid or non-allowed properties
		%>
		%> @param args input structure
		% ===================================================================
			args = octickaCore.makeArgs(args);
			if isstruct(args)
				fnames = intersect(findAttributes(me,'SetAccess','public'),fieldnames(args));
				for i=1:length(fnames)
					try
						me.(fnames{i})=args.(fnames{i}); %we set up the properies from the arguments as a structure
						me.logOutput(fnames{i},'SET property');
					catch
						me.logOutput(fnames{i},'Property INVALID!',true);
					end
				end
			end
		end

		% ===================================================================
		function setPaths(me)
		%> @brief set paths for object
		%>
		%> @param
		% ===================================================================
			me.paths(1).whatami = me.className;
			me.paths.root = fileparts(which('octickaCore.m'));
			me.paths.whereami = fileparts(mfilename('fullpath'));
			if ~isfield(me.paths, 'stateInfoFile')
				me.paths.stateInfoFile = '';
			end
			if ismac || isunix
				me.paths.home = getenv('HOME');
			else
				me.paths.home = 'C:';
			end
			me.paths.parent = [me.paths.home filesep 'OctickaFiles'];
			if ~isfolder(me.paths.parent)
				status = mkdir(me.paths.parent);
				if status == 0; warning('Could not create OctickaFiles folder'); end
			end
			me.paths.savedData = [me.paths.parent filesep 'SavedData'];
			if ~isfolder(me.paths.savedData)
				status = mkdir(me.paths.savedData);
				if status == 0; warning('Could not create SavedData folder'); end
			end
			me.paths.protocols = [me.paths.parent filesep 'Protocols'];
			if ~isfolder(me.paths.protocols)
				status = mkdir(me.paths.protocols);
				if status == 0; warning('Could not create Protocols folder'); end
			end
			me.paths.calibration = [me.paths.parent filesep 'Calibration'];
			if ~isfolder(me.paths.calibration)
				status = mkdir(me.paths.calibration);
				if status == 0; warning('Could not create Calibration folder'); end
			end
			if isdeployed
				me.paths.deploypath = ctfroot;
			end
		end

		% ===================================================================
		function getFonts(me)
		%> @fn getFonts(me)
		%> @brief Checks OS and assigns a sans and mono font
			if exist('listfonts','file')
				lf = listfonts;
			else
				lf = {};
			end
			if ismac
				me.sansFont = 'Avenir Next';
				me.monoFont = 'Menlo';
			elseif ispc
				me.sansFont = 'Calibri';
				me.monoFont = 'Consolas';
			else %linux
				me.sansFont = 'Ubuntu';
				me.monoFont = 'Ubuntu Mono';
			end
			if any(strcmpi('Graublau Sans', lf))
				me.sansFont = 'Graublau Sans';
			elseif any(strcmpi('Source Sans 3', lf))
				me.sansFont = 'Source Sans 3';
			elseif any(strcmpi('Source Sans Pro', lf))
				me.sansFont = 'Source Sans Pro';
			end
			if any(strcmpi('Fira Code', lf))
				me.monoFont = 'Fira Code';
			elseif any(strcmpi('Cascadia Code', lf))
				me.monoFont = 'Cascadia Code';
			elseif any(strcmpi('JetBrains Mono', lf))
				me.monoFont = 'JetBrains Mono';
			end
		end

		% ===================================================================
		function out=toStructure(me)
		%> @fn out=toStructure(me)
		%> @brief Converts properties to a structure
		%>
		%>
		%> @param me this instance object
		%> @param tmp is whether to use the temporary or permanent properties
		%> @return out the structure
		% ===================================================================
			fn = fieldnames(me);
			for j=1:length(fn)
				out.(fn{j}) = me.(fn{j});
			end
		end

		% ===================================================================
		function out = getType(me, in)
		%> @brief Give a metaproperty return the likely property class
		%>
		%>
		%> @param me this instance object
		%> @param in metaproperty
		%> @return out class name
		% ===================================================================
			out = 'undefined';
			thisClass = '';
			if in.HasDefault
				thisClass = class(in.DefaultValue);
				if strcmpi(thisClass,'double') && length(in.DefaultValue) > 1
					thisClass = '{[double vector],[]}';
				end
			elseif ~isempty(in.Validation) && ~isempty(in.Validation.Class)
				thisClass = in.Validation.Class.Name;
			end
			if ~isempty(thisClass); out = thisClass; end
		end


		% ===================================================================
		function logOutput(me, in, message, override)
		%> @brief Prints messages dependent on verbosity
		%>
		%> Prints messages dependent on verbosity
		%> @param me this instance object
		%> @param in the calling function or main info
		%> @param message additional message that needs printing to command window
		%> @param override force logging if true even if verbose is false
		% ===================================================================
			if ~exist('override','var');override = false;end
			if override==false && me.verbose==false; return; end
			if ~exist('in','var'); in = 'Unknown'; end
			if isnumeric(in);in=num2str(in);end
			if ~exist('message','var') || isempty(message) || ~ischar(message)
				fprintf(['---> ' me.fullName_ ': ' in '\n']);
			else
				fprintf(['---> ' me.fullName_ ': ' message ' | ' in '\n']);
			end
		end

	end
end
