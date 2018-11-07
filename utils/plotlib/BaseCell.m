classdef BaseCell < handle
    % BaseCell superclass containing common info about cells.
    %
    % The contructor requires the following outputs:
    %
    % :Param.posScheme: (str) Chose a predefined scheme/scenario. If none is chosen custom setup is used.
    % :Param.macroHeight: (double) Height of the macro eNB.
    % :Param.microHeight: (double) Height of the micro eNB.
    % :Param.picoHeight: (double) Height of the pico eNB.
    % :Param.macroRadius: (double) Radius or ISD for macrocells.
    % :Param.microDist: (double) Minimum ditance between microcells.


    %Properties
    properties 
    Center;
    Radius;
    CellID;
    CellType;
    PosScenario;
    Height;
    end

    methods 
        function obj =BaseCell(xc, yc, Param, cellId, cellType)
            %Constructor

            %Set arguments
            obj.Center  = [xc yc];
            obj.CellID = cellId;
            obj.CellType = cellType;
            obj.PosScenario = Param.posScheme;
            %Set positioning scenario accordingly, currently not implemented fully.
            switch cellType
                case 'macro'
                    obj.Height = Param.macroHeight;
                    obj.Radius = Param.macroRadius;
                case 'micro'
                    obj.Height = Param.microHeight;
                    obj.Radius = Param.microDist;
                case 'pico'
                    obj.Height = Param.picoHeight;
                    obj.Radius = 5;
                otherwise
                    sonohilog('Unknown cell type selected.','ERR')
            end   

        end

    end


    
end