classdef touchData < octickaCore

	properties
		subject
		data
	end

	properties (Dependant = true)
		nSessions
	end

	properties (Access = protected)
		dataTemplate = struct('date',[],'comment',[],'phase',1,'trials',[],'result',[],'rt',[])
		allowedProperties = {'subject'}
	end

	methods

		function me = touchData(varargin)
			args = octickaCore.addDefaults(varargin,struct('name','touchManager'));
			me = me@octickaCore(args); %superclass constructor
			me.parseArgs(args, me.allowedProperties);

			if isempty(me.data)
				me.data = me.dataTemplate;
			end

		end


	end

end
