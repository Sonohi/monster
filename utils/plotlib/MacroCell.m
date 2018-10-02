%Class defining all relevnt coordinates in a hexagonal cell
classdef MacroCell < handle

    %Properties
    properties 
        Center;
        Radius;
        Edges;
        Corners;
        Area;
        CellID;
    end

    methods 
        function obj = MacroCell(xc, yc, Param, cellId)
            %Constructor

            %Set arguments
            obj.Center  = [xc yc];
            obj.Radius  = Param.macroRadius;
            obj.computeEdges();
            obj.computeCorners();
            obj.Area    = 2*sqrt(3)*Param.macroRadius^2;
            obj.CellID = cellId;

        end

    end

    methods (Access = private)
        function obj = computeEdges(obj)
            %compute coordinates of middle of edges
            edges = zeros(6,2);
            rho = pi/6;
            theta = pi/3;
            for i=1:6;
                edges(i,1) = obj.Center(1) + obj.Radius*sqrt(3)/2*cos(rho+i*theta);
                edges(i,2) = obj.Center(2) + obj.Radius*sqrt(3)/2*sin(rho+i*theta);
            end
            obj.Edges = edges;
        end

        function obj = computeCorners(obj)
            %Compute coordinates of corners in the hexagon
            corners = zeros(6,2);
            rho = 0;
            theta = pi/3;
            for i=1:6
                corners(i,1) = obj.Center(1) + obj.Radius*cos(rho+i*theta);
                corners(i,2) = obj.Center(2) + obj.Radius*sin(rho+i*theta);
            end
            obj.Corners = corners;
        end

    end

end
