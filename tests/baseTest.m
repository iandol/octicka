classdef baseTest < rootTest

	properties
		size = 2
		%dynamic properties held here
		dp = []
	end

	methods

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
		function prop = addProperty(me, prop)
			if nargin < 2 || ~ischar(prop) || isempty(prop) || isempty(me)
				error([ mfilename ': addprop: Parameter must be a string.' ]);
			end
			if isempty(me.dp); me.dp = struct(); end
			prop = prop(:)';
			if ~isvarname(prop)
				error([ mfilename ': addprop: Parameter must be a valid property name.' ]);
			end
			me.dp.(prop)=[];
		end

		function pTest(me)
			persistent f
			if isempty(f)
				f = randi(10);
				fprintf('Init f = %i\n',f);
			else
				fprintf('Hello f = %i\n',f);
			end
		end

		% ===================================================================
		function v = subsref(me,S)
			S = subs_added(me, S);
			v = builtin('subsref', me, S);
		end

		% ===================================================================
		function a=subsasgn(me, S, v)
			if ismethod(me, 'setOut')
				fprintf('We are modifying the Value for %s\n',S(1).subs);
				v = me.setOut(S, v); % this is a pseudo Set method
			end
			S = subs_added(me,S);
			a = builtin('subsasgn', me, S, v);
		end

		% ===================================================================
		function S = subs_added(me, S)
			if isempty(S); return; end
			if ischar(S); S=struct('type', '.', 'subs', S); end
			if ~isstruct(me.dp);S=[];return;end
			f = fieldnames(me.dp);
			if isempty(f); return; end
			if strcmp(S(1).type, '.') && ismember(S(1).subs, f)
				fprintf('We are modifying the Assign for %s\n',S(1).subs);
				S0 = struct('type', '.', 'subs', 'dp');
				S = [ S0 S ];
			end
		end

	end


end
