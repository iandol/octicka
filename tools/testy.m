classdef testy < dynamicprops
  
  properties 
    test = 'hi'
  end
  
  properties (Dependent = true)
    delta
  end
  
  methods
    
    function me = testy(varargin)
      p = addprop(me,'test2');
    end
    
    function value = get.delta(me)
      value = 42;
    end
    
    function set.test(me,value);
      me.test = [me.test ' ' value];
    end
    
    function v = runMod(me,S,v)
      disp('hi from runMod')
      disp(S(1))
      switch S.subs
        case 'doe'
          disp('hi from case');
          v=v*2;
      end
    end
    
  end %methods
  
  
 end % classdef