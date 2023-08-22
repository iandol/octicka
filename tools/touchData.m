classdef touchData < octickaCore

	properties
		subject
		data
	end

	properties (GetAccess = public, SetAccess = protected)
		nData
		nSessions
	end

	properties (Access = protected)
		dataTemplate = struct('date',[],'comment',[],'phase',[],'time',[],'trials',[],'result',[],'rt',[])
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

		function update(me,result,phase,trials,rt)
			if ~exist('result','var'); return; end
			if isempty(me.nData) || me.nData == 0
				me.data = me.dataTemplate
				me.data(1).date = clock;
				n = 1;
			else
				n = me.nData + 1;
			end
			me.data.time(n) = GetSecs;
			me.data.result(n) = result;
			if exist('phase','var'); me.data.phase(n) = phase; end
			if exist('phase','var'); me.data.phase(n) = phase; end
			if exist('trials','var'); me.data.trials(n) = trials; end
			if exist('rt','var'); me.data.rt(n) = rt; end
			me.nData = n;
		end

	end

	methods (Static = true)
		function plot(in)
			if isfield(in,'className') && ~strcmp(in.className, 'touchData'); return; end
			if isempty(d.data.trials); return; end
			time = in.data.time - in.data.time(1);
			figure
			subplot(3,1,1);
			plot(in.data.trials,in.data.result);
			xlabel('Trial Number')
			ylabel('Correct/Incorrect');
			subplot(3,1,2);
			plot(time,in.data.phase);
			xlabel('Time')
			ylabel('Task Step');
			subplot(3,1,3);
			plot(time,in.data.rt);
			xlabel('Time')
			ylabel('Trial Time');
		end
	end

end
