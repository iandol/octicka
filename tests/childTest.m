classdef childTest < baseTest
	
	properties
		angle = 0
	end
	
	methods
		
		function me = childTest(varargin)
			%me=me@baseTest(varargin); %superclass constructor
		end
		
		function setup(me)
			% we copy our properties to dp
			fn = fieldnames(me);
			for j=1:length(fn)
				prop = [fn{j} 'Out'];
				p = addProperty(me, prop);
				me.dp.(p) = me.(fn{j}); %copy our property value to our tempory copy
			end
		end
		
	end
	
end
