%Class defining a Pico cell
classdef PicoCell < BaseCell

    %Properties
    properties 

    end

    methods 
        function obj = PicoCell(xc, yc, Param, cellId)
            %Constructor
            obj = obj@BaseCell(xc, yc, Param, cellId, 'pico')
            %Set arguments
            
            
        end

    end

    methods (Access = private)
       
        

        
    end

end
