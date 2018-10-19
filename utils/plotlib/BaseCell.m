classdef BaseCell < handle

    %Properties
    properties 
    Center;
    Radius;
    CellID;
    CellType;
    PosScenario;
    end

    methods 
        function obj =BaseCell(xc, yc, Param, cellId, cellType)
            %Constructor

            %Set arguments
            obj.Center  = [xc yc];
            obj.CellID = cellId;
            obj.CellType = cellType;
            %Set positioning scenario accordingly, currently not implemented fully.
            switch cellType
                case 'macro'
                    obj.PosScenario = 'hexagonal';
                    obj.Radius = Param.macroRadius;
                case 'micro'
                    obj.PosScenario = Param.microPos;
                    obj.Radius = Param.microUniformRadius;
                case 'pico'
                    obj.PosScenario = Param.picoPos;
                    obj.Radius = Param.picoUniformRadius;
                otherwise
                    sonohilog('Unknown cell type selected.','ERR')
            end   

        end

    end


    
end