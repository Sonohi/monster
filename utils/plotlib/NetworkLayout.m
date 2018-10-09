classdef NetworkLayout < handle
    %This is the class defining the layout for macro cells

    properties 
        Center;             %Center of the target area
        MacroCoordinates;   %Center of each macro cell
        Cells;              %Cell array containing all macro cell obj
        Radius;             %The ISD of macrocells
        NumMacro;                %The number of macro cells
        NumMicro;
        NumPico;
        MicroCoordinates;    %Coordinates of the micro BST, placed on the middle of the edges of the cell border
        PicoCoordinates;
    end

    methods 
        function obj = NetworkLayout(xc, yc, Param)
            %Constructor functions
            obj.Center = [xc yc];
            obj.Radius = Param.macroRadius;
            obj.NumMacro = Param.numMacro;
            obj.computeMacroCoordinates();
            obj.generateCells(Param);
            obj.findMicroCoordinates(Param);
            obj.findPicoCoordinates(Param);
            obj.NumMicro = length(obj.MicroCoordinates(:,1))
            obj.NumPico = length(obj.PicoCoordinates(:,1))
        end

        function draweNBs(obj, Param)
            buildings = Param.buildings;

            %Find simulation area
            area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
                max(buildings(:, 4))];

            % Draw grid first

            for i = 1:length(buildings(:,1))
                x0 = buildings(i,1);
                y0 = buildings(i,2);
                x = buildings(i,3)-x0;
                y = buildings(i,4)-y0;
                rectangle(Param.LayoutAxes,'Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
            end

            %Draw macros
            for i=1:obj.NumMacro
                xc = obj.Cells{i}.Center(1);
                yc = obj.Cells{i}.Center(2);
                text(Param.LayoutAxes,xc,yc-20,strcat('Macro BS (',num2str(round(xc)),', ',num2str(round(yc)),')'),'HorizontalAlignment','center');
                [macroImg, ~, alpha] = imread('utils/images/macro.png');
                % For some magical reason the image is rotated 180 degrees.
                macroImg = imrotate(macroImg,180);
                alpha = imrotate(alpha,180);
                % Scale size of figure
                scale = 30;
                macroLengthY = length(macroImg(:,1,1))/scale;
                macroLengthX = length(macroImg(1,:,1))/scale;
                % Position and set alpha from png image
                f = imagesc(Param.LayoutAxes,[xc-macroLengthX xc+macroLengthX],[yc-macroLengthY yc+macroLengthY],macroImg);
                set(f, 'AlphaData', alpha);
                %Draw 3 sectors as hexagons (flat top and bottom)		
                theta = pi/3;
                xyHex = zeros(7,2);
                for i=1:3 
                    cHex = [(xc + obj.Cells{1}.CellRadius * cos((i-1)*2*theta)) ...
                            (yc + obj.Cells{1}.CellRadius * sin((i-1)*2*theta))];
                    for j=1:7
                        xyHex(j,1) = cHex(1) + obj.Cells{1}.CellRadius*cos(j*theta);
                        xyHex(j,2) = cHex(2) + obj.Cells{1}.CellRadius*sin(j*theta);
                    end

                    l = line(Param.LayoutAxes,xyHex(:,1),xyHex(:,2), 'Color', 'k');
                    set(get(get(l,'Annotation'),'LegendInformation'),'IconDisplayStyle','off')

                end
            end

            %Draw Micros
            [microImg, ~, alpha] = imread('utils/images/micro.png');
            % For some magical reason the image is rotated 180 degrees.
            microImg = imrotate(microImg,180);
            alpha = imrotate(alpha,180);
            % Scale size of figure
            scale = 30;
            microLengthY = length(microImg(:,1,1))/scale;
            microLengthX = length(microImg(1,:,1))/scale;

            for i=1:obj.NumMicro
                % d = sqrt((macroPos(1, 1) - microPos(i,1)) ^ 2 + (macroPos(1, 2) - microPos(i,2)) ^ 2);
                % if d< maxInterferrenceDistMicro2Macro
                % 	sonohilog(strcat('Warning! Too high interferrence detected between macro and micro BST at',num2str(microPos(i,1)),',',num2str(microPos(i,2))),'WRN');
                % end
                xr = obj.MicroCoordinates(i,1);
                yr = obj.MicroCoordinates(i,2);

                f = imagesc(Param.LayoutAxes,[xr-microLengthX xr+microLengthX],[yr-microLengthY yr+microLengthY],microImg);
                set(f, 'AlphaData', alpha);
                
                text(xr,yr+20,strcat('Micro BS ', num2str(i+1),' (',num2str(round(xr)),', ', ...
                    num2str(round(yr)),')'),'HorizontalAlignment','center','FontSize',9);
            end

            %Draw Picos
            [picoImg, ~, alpha] = imread('utils/images/pico.png');
            % For some magical reason the image is rotated 180 degrees.
            picoImg = imrotate(picoImg,180);
            alpha = imrotate(alpha,180);
            % Scale size of figure
            scale = 30;
            picoLengthY = length(picoImg(:,1,1))/scale;
            picoLengthX = length(picoImg(1,:,1))/scale;

            for i=1:obj.NumPico
                x = obj.PicoCoordinates(i,1);
                y = obj.PicoCoordinates(i,2);
                text(x,y+20,strcat('Pico BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
                    num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
                        
                f = imagesc(Param.LayoutAxes,[x-picoLengthX x+picoLengthX],[y-picoLengthY y+picoLengthY],picoImg);
                set(f, 'AlphaData', alpha);
                drawnow
                
        
            end
        end
    end

    methods (Access = private)

        function obj = computeMacroCoordinates(obj)
            %Computes the center coordinates by walking in hexagons around the center
            centers = zeros(obj.NumMacro,2);
            steps = 1;
            rings =1;
            theta = 2/3*pi;
            special = false;
            specialTrack = false;
            turn = true;
            rho = pi/3;
            stepTrack = 0;
            %Two first coordinates are "special" cases and are done seperately.
            centers(1,:) =obj.Center;
            if obj.NumMacro > 1
                centers(2,1) = obj.Center(1,1)+obj.Radius*cos(rho);
                centers(2,2) = obj.Center(1,2)+obj.Radius*sin(rho);
            end
            %Rest of the coordinates follow the same pattern, but when going out one "ring" a special action are carried out.
            for i=3:obj.NumMacro
                if special
                    %Perform special action
                    centers(i,1) = centers(i-1,1) + obj.Radius*cos(theta+rho);
                    centers(i,2) = centers(i-1,2) + obj.Radius*sin(theta+rho);
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
                    centers(i,1) = centers(i-1,1) + obj.Radius*cos(theta+rho);
                    centers(i,2) = centers(i-1,2) + obj.Radius*sin(theta+rho);
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
            obj.MacroCoordinates = centers;
        end
        %Generate Macrocell objects from MacroCoordinates
        function obj = generateCells(obj,Param)
            cells = cell(obj.NumMacro,1);
            for i=1:obj.NumMacro
                cells(i)={MacroCell(obj.MacroCoordinates(i,1),obj.MacroCoordinates(i,2),Param,i)};
            end
            obj.Cells = cells;
        end

        %Find the coordinates of all microcells in all macrocells
        function obj = findMicroCoordinates(obj,Param)
            
            microCenters = zeros(Param.numMicro,2);
            iMicro = 1;
            iMacro = 1;
            while iMicro <= Param.numMicro && iMacro <= obj.NumMacro
                for i=1:9 %up to 9 positions per macro site

                    %Find the micro stations that are actually set up, e.i. more than 9 micro stations pr macro site is not supported
                    if iMicro <= Param.numMicro 
                        microCenters(iMicro,:) = obj.Cells{iMacro}.MicroPos(i,:);
                        iMicro = iMicro +1 ;
                    end
                end
                iMacro = iMacro +1;
            end
           %informs if microstations were unable to be placed
            if iMicro-1 < Param.numMicro
                sonohilog(strcat('Cannot place the last  ', num2str(Param.numMicro-(iMicro-1)),' micro BST.'),'WRN');
            end
            obj.MicroCoordinates = microCenters(1:iMicro-1,:);
        end

        %Find the coordinates of all picocells in all macrocells
        function obj = findPicoCoordinates(obj,Param)
            
            picoCenters = zeros(Param.numPico,2);
            iPico = 1;
            for i=1:obj.NumMacro
                nPico = length(obj.Cells{i}.PicoPos(:,1));
                picoCenters(iPico:iPico+nPico-1,:) = obj.Cells{i}.PicoPos;
                iPico = iPico+ nPico;
            end
            obj.PicoCoordinates = picoCenters(1:iPico-1,:);
        end

    end

end