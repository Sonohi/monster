classdef Car < handle
    properties
        Wheel;
        Color;
        TheStruct;
    end
    
    methods 
        function obj = Car(c, num)
            if nargin == 0 
                obj.Color = 'pink';
            else                
                obj.Color = c;
            end
        end
        
        function changeColor(obj, newColor)
            obj.Color = newColor;
        end
    end
    
end

 