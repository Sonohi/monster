classdef NetworkLayout < handle
    %This is the class defining the layout for macro cells

    properties 
        Center;             %Center of the target area
        CenterCoordinates;  %Center of each macro cell
        Cells;              %Cell array containing all macro cell obj
        Radius;             %The radius of a single macrocell
        Num;                %The number of macro cells
        MicroCoordinates;    %Coordinates of the micro BST, placed on the middle of the edges of the cell border
    end

    methods 
        function obj = NetworkLayout(xc, yc, Param)
            %Constructor functions
            obj.Center = [xc yc];
            obj.Radius = Param.macroRadius;
            obj.Num = Param.numMacro;
            obj.computeCenterCoordinates();
            obj.generateCells(Param);
            obj.findMicroCoodinates(Param);
        end
    end

    methods (Access = private)

        function obj = computeCenterCoordinates(obj)
            %Computes the center coordinates by walking in hexagons around the center
            centers = zeros(obj.Num,2);
            steps = 1;
            rings =1;
            theta = 2/3*pi;
            special = false;
            specialTrack = false;
            turn = true;
            rho = pi/6;
            stepTrack = 0;
            %Two first coordinates are "special" cases and are done seperately.
            centers(1,:) =obj.Center;
            if obj.Num > 1
                centers(2,1) = obj.Center(1,1)+sqrt(3)*obj.Radius*cos(rho);
                centers(2,2) = obj.Center(1,2)+sqrt(3)*obj.Radius*sin(rho);
            end
            %Rest of the coordinates follow the same pattern, but when going out one "ring" a special action are carried out.
            for i=3:obj.Num
                if special
                    %Perform special action
                    centers(i,1) = centers(i-1,1) + sqrt(3)*obj.Radius*cos(theta+rho);
                    centers(i,2) = centers(i-1,2) + sqrt(3)*obj.Radius*sin(theta+rho);
                    stepTrack = stepTrack +1;
                    turn = false;
                    if stepTrack == rings-1
                        
                        turn = true;
                    end
                    if stepTrack == rings -1 && specialTrack
                        turn = true;
                        special = false;  
                    end
                    if turn
                        theta =theta + pi/3;
                        stepTrack = 0;
                        specialTrack = true;
                        if special ==false
                            stepTrack = 0;
                            specialTrack = false;
                        end
                    end
                else
                    %walk, then update
                    centers(i,1) = centers(i-1,1) + sqrt(3)*obj.Radius*cos(theta+rho);
                    centers(i,2) = centers(i-1,2) + sqrt(3)*obj.Radius*sin(theta+rho);
                    stepTrack = stepTrack +1;
                    turn = false;
                    if stepTrack == rings
                        turn = true;
                        stepTrack = 0;
                    end
                    if turn && steps <5
                        theta =theta + pi/3;
                        steps = steps +1;
                    elseif 5 <= steps
                        rings = rings +1;
                        steps = 1;
                        special = true;
                        stepTrack = 0;
                        turn = false;
                    end
                end
            end
            obj.CenterCoordinates = centers;
        end
        %Generate Macrocell objects from CenterCoordinates
        function obj = generateCells(obj,Param)
            cells = cell(obj.Num,1);
            for i=1:obj.Num
                cells(i)={MacroCell(obj.CenterCoordinates(i,1),obj.CenterCoordinates(i,2),Param,i)};
            end
            obj.Cells = cells;
        end
        %Generate Microcell coordinates from edges of macro cells.
        %Each coordinate occurs only once and are placed around the center macro BST until there are no more micro cells.
        function obj = findMicroCoodinates(obj,Param)
            microCenters = zeros(Param.numMicro,2);
            iMicro = 1;
            iMacro = 1;
            while iMicro <= Param.numMicro && iMacro <= obj.Num
                for i=1:6 %up to 6 positions per macro BST
                    duplicate =false;
                    if iMicro <= Param.numMicro 
                        %If there is already a micro BST skip that coordinate
                        for j=1:Param.numMicro
                            if round(microCenters(j,:),4) == round(obj.Cells{iMacro}.Edges(i,:),4)
                                duplicate = true;
                            end
                        end
                        if ~duplicate || iMicro < 7
                            microCenters(iMicro,:) = obj.Cells{iMacro}.Edges(i,:);
                            iMicro = iMicro +1 ;
                        end
                    end
                end
                iMacro = iMacro +1;
            end
            %remove extra 0's
            if iMicro-1 < Param.numMicro
                sonohilog(strcat('Cannot place the last  ',num2str(Param.numMicro-(iMicro-1)),' micro BST.'),'WRN');
            end
            obj.MicroCoordinates = microCenters(1:iMicro-1,:);
        end
    end

end