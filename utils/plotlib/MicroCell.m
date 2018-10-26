%Class defining a microcell
classdef MicroCell < BaseCell

    %Properties
    properties 

    end

    methods 
        function obj = MicroCell(xc, yc, Param, cellId)
            %Constructor
            obj = obj@BaseCell(xc, yc, Param, cellId, 'micro')
            %Set arguments
            
            
        end

    end

    methods (Access = private)
       
        

        
    end

end
