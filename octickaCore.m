% ========================================================================
%> @class octickaCore
%> @brief octickaCore base class inherited by many other octicka classes.
%>
%>
%> Copyright ©2014-2022 Ian Max Andolina — released: LGPL3, see LICENCE.md
% ========================================================================
classdef octickaCore < handle
	
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
		dateStamp 
		%> universal ID
		uuid 
		%> storage of various paths
		paths 
	end
	
	%--------------------TRANSIENT PROPERTIES----------%
	properties (SetAccess = protected, GetAccess = protected, Transient = true)
		%> Octave version number, this is transient so it is not saved
		oversion  = 0
	end
	
	%--------------------PROTECTED PROPERTIES----------%
	properties (SetAccess = protected, GetAccess = protected)
		%> class name
		className  = ''
		%> save prefix generated from clock time
		savePrefix
	end
	
	%--------------------PRIVATE PROPERTIES----------%
	properties (Access = private)
		%> allowed properties passed to object upon construction
		allowedPropertiesCore  = 'name|comment|cloning'
		%> cached full name
		fullName_
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
			args = me.addDefaults(varargin);
			me.parseArgs(args,me.allowedPropertiesCore);
			me.dateStamp = clock();
			me.className = class(me);
			me.uuid = num2str(dec2hex(floor((now - floor(now))*1e10))); %me.uuid = char(java.util.UUID.randomUUID)%128bit uuid
			me.oversion = str2double(regexp(version,'(?<ver>^\d\.\d[\d]?)','match','once'));
			setPaths(me)
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
    function ret = isProperty(me, prop);
			persistent f
			if isempty(f);f = fieldnames(me);end
      if any(strcmp(f, 'dp')) && ~isempty(me.dp)
         ff = fieldnames(me.dp);
         f = [f;ff];
      end
      ret = any(strcmp(f, prop));
    end
		
		% ===================================================================
		function setProp(me, property, value)
		%> @fn set
		%> @brief method to fast change a particular value. This is
		%> useful for use in anonymous functions, like in the state machine.
		%>
		%> @param property — the property to change
		%> @param value — the value to change it to
		% ===================================================================
			if isProperty(me,property)
				me.(property) = value;
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
						warning('Can''t find valid source directory')
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
							warning('Can''t find valid source directory')
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
				error('---> makeArgs: You need to pass name:value pairs / structure of name:value fields!')
			end
		end
		
		% ===================================================================
		function args = addDefaults(args, defs)
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
		
	end %--------END STATIC METHODS
	
	%=======================================================================
	methods ( Access = protected ) %-------PROTECTED METHODS-----%
	%=======================================================================
		
		% ===================================================================
		function parseArgs(me, args, allowedProperties)
		%> @brief Sets properties from a structure or normal arguments pairs,
		%> ignores invalid or non-allowed properties
		%>
		%> @param args input structure
		%> @param allowedProperties properties possible to set on construction
		% ===================================================================
			allowedProperties = ['^(' allowedProperties ')$'];
			
			args = octickaCore.makeArgs(args);

			if isstruct(args)
				fnames = fieldnames(args); %find our argument names
				for i=1:length(fnames)
					if regexpi(fnames{i},allowedProperties) %only set if allowed property
						me.salutation(fnames{i},'Parsing input argument');
						try
							me.(fnames{i})=args.(fnames{i}); %we set up the properies from the arguments as a structure
						catch
							me.salutation(fnames{i},'Propery invalid!',true);
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
						me.salutation(fnames{i},'SET property')
					catch
						me.salutation(fnames{i},'Property INVALID!',true);
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
			me.paths.root = fileparts(which(mfilename));
			me.paths.whereami = me.paths.root;
			if ~isfield(me.paths, 'stateInfoFile')
				me.paths.stateInfoFile = '';
			end
			if ismac || isunix
				me.paths.home = getenv('HOME');
			else
				me.paths.home = 'C:';
			end
			me.paths.parent = [me.paths.home filesep 'octickaFiles'];
			if ~isfolder(me.paths.parent)
				status = mkdir(me.paths.parent);
				if status == 0; warning('Could not create octickaFiles folder'); end
			end
			me.paths.savedData = [me.paths.parent filesep 'SavedData'];
			if ~isfolder(me.paths.savedData)
				status = mkdir(me.paths.savedData);
				if status == 0; warning('Could not create SavedData folder'); end
			end
			me.paths.protocols = [me.paths.parent filesep 'protocols'];
			if ~isfolder(me.paths.savedData)
				status = mkdir(me.paths.savedData);
				if status == 0; warning('Could not create SavedData folder'); end
			end
			if isdeployed
				me.paths.deploypath = ctfroot;
			end
		end
		
		% ===================================================================
		function out=toStructure(me)
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
		function salutation(me, in, message, override)
		%> @brief Prints messages dependent on verbosity
		%>
		%> Prints messages dependent on verbosity
		%> @param me this instance object
		%> @param in the calling function or main info
		%> @param message additional message that needs printing to command window
		%> @param override force logging if true even if verbose is false
		% ===================================================================
			if ~exist('override','var');override = false;end
			if me.verbose==true || override == true
				if ~exist('message','var') || isempty(message)
					fprintf(['---> ' me.fullName_ ': ' in '\n']);
				else
					fprintf(['---> ' me.fullName_ ': ' message ' | ' in '\n']);
				end
			end
		end
		
	end
end
