classdef (Abstract) dynamicprops < handle

	properties
		dp = []; ## Properties dynamically added
	end
  
  methods
		
    function prop = addprop(me, prop)  
      if nargin < 2 || ~ischar(prop) || isempty(prop) || isempty(me)
        error([ mfilename ': addprop: Parameter must be a string.' ]); 
      end
      prop = prop(:)';
      if ~isvarname(prop)
        error([ mfilename ': addprop: Parameter must be a valid property name.' ]); 
      end
      me.dp.(prop)=[];
    end ## addprop
    
    function v = subsref(me,S)
      S = subs_added(me, S);
      v = builtin('subsref', me, S);
    end
    
    function a=subsasgn(me,S, v)
      if ismethod(me, 'setOut')
        v = me.setOut(S,v); % this is a fake Set method
      end
      S = subs_added(me,S);
      a = builtin('subsasgn', me, S, v);
    end
    
  end ## methods
  
  methods (Access=protected)
  
    function S = subs_added(me,S)
      if isempty(S), return; end
      if isempty(me.dp), return; end
      if ischar(S), S=struct('type','.','subs', S); end
      f     = fieldnames(me.dp);
      index = find(strcmp(S(1).subs, f));
      if strcmp(S(1).type, '.') && ~isempty(index)
        S0 = struct('type','.' ,'subs', 'dp');
        S = [ S0 S ];
      end
      
    end ## subs_added
    
  end ## methods protected
end ## classdef dynamicprops
