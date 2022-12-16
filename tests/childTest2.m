classdef childTest2 < baseTest
	
	properties
		angle = 0
	end
	
	properties (Access = protected)
		ignoreProperties = {'dp','uuid','dateStamp'}
	end
	
	methods
		
		% ===================================================================
		function me = childTest2(varargin)
			%me=me@baseTest(varargin); %superclass constructor
		end
		
		% ===================================================================
		function setup(me)
			% we copy our properties to dp
			fn = fieldnames(me);
			for j=1:length(fn)
				if ~ismember(fn{j}, me.ignoreProperties)
					prop = [fn{j} 'Out'];
					p = addProperty(me, prop);
					me.dp.(p) = me.(fn{j}); %copy our property value to our tempory copy
				end
			end
		end
		
		function callMe(me)
			
			if isProperty(me, 'sizeOut')
				s = me.dp.sizeOut;
				fprintf('callMe: Size = %.2f\n',s);
			end
			
		end
		
		% ===================================================================
		function v = setOut(me, S, v)
      if strcmp(S(1).type, '.')
        switch S(1).subs
				case {'angleOut'}
					v = v*2;
				case {'sizeOut'}
					v = v/2;
        end
      end
		end
		
	end
	
end
