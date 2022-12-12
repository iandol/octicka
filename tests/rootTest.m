classdef rootTest < handle
	
	properties 
		name = ''
	end
	
	%--------------------VISIBLE PROPERTIES-----------%
	properties (SetAccess = protected, GetAccess = public)
		%> clock() dateStamp set on construction
		dateStamp 
		%> universal ID
		uuid 
	end
	
	methods
		
		% ===================================================================
    function me = rootTest()
			me.name = 'test';
			me.dateStamp = clock();
			me.uuid = num2str(dec2hex(floor((now - floor(now))*1e10))); %me.uuid = char(java.util.UUID.randomUUID)%128bit uuid
		end
		
	end
	
	methods (Access = protected)
		
		
		
	end
	
	
end
