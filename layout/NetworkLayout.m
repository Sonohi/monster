classdef NetworkLayout < handle
    % This is the class defining the layout and placement of the different cells.
    %
    % Currently implmented standard scenarioes: [:attr:`3GPP TR 38.901 UMa`, :attr:`3GPP TR 38.901 RMa`, :attr:`ITU-R M.2412-0 5.B.C`, :attr:`ITU-R M.2412-0 5.B.A`, :attr:`Single Cell`]
    %
    % The constructor requires the following:
    %
    % :input Param: Parameter struct containing the following:
    % :Param.numMacro: (int) Number of Macro sites. Each Site corersponds to 3 macrocells in a hexagonal structure.
    % :Param.numMicro: (int) Number of Micro sites. Placement restricted to how the macrocells are placed.
    % :Param.numPico: (int) Number of Pico cells, randomly placed.
    % :Param.macroRadius: (double) Radius or ISD for macrocells.
    % :Param.posScheme: (str) Chose a predefined scheme/scenario. If none is chosen custom setup is used.
    % :Param.buildings: (2-dimensional array of double) Building coordinaates defining the layout of the city.
    % From _ITU M.2412-0: https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf table 5.b configuration C
    %
    % +---------------------+------------------------------------------------------+
    % | Carrier frequency   | 4 GHz and 30 GHz available in macro and micro layers | 
    % +---------------------+------------------------------------------------------+
    % | BS antenna height   | 25m for macro and 10m for micro                      |
    % +---------------------+------------------------------------------------------+
    % | Total transmit      | -Macro 4 GHz:                                        |
    % | power pr TRxP       |   44 dBm for 20 MHz bandwidth                        |
    % |                     |   41 dBm for 10 MHz bandwidth                        |
    % |                     | -Macro 30 GHz:                                       |
    % |                     |   40 dBm for 80 MHz bandwidth                        |
    % |                     |   37 dBm for 40 MHz bandwidth                        |
    % |                     |   e.i.r.p. should not exceed 73 dBm                  |
    % |                     | -Micro 4 GHz:                                        |
    % |                     |   33 dBm for 20 MHz bandwidth                        |
    % |                     |   30 dBm for 10 MHz bandwidth                        |
    % |                     | -Micro 30 GHz:                                       |
    % |                     |   33 dBm for 80 MHz bandwidth                        |
    % |                     |   30 dBm for 40 MHz bandwidth                        |
    % |                     |   e.i.r.p. should not exceed 68 dBm                  |
    % +---------------------+------------------------------------------------------+
    % |UE power class       | 4 GHz: 23 dBm                                        |
    % |                     | 30 GHz: 23 dBm, e.i.r.p should not exceed 43 dBm     |
    % +---------------------+------------------------------------------------------+
    % | Percentage of high  | 20% high loss, 80% low loss                          |
    % | and low loss        |                                                      |
    % | building type       |                                                      |
    % +---------------------+------------------------------------------------------+
    % | Inter-site distance | Macro layer: 200m, micro layer can be seen in figure |
    % +---------------------+------------------------------------------------------+
    % | Number of antenna   | Up to 256 Tx/Rx                                      |
    % | elements pr TRxp    |                                                      |
    % +---------------------+------------------------------------------------------+
    % | Number of UE        | 4 GHz: Up to 8 Tx/Rx                                 |
    % | antenna elements    | 30 GHz: Up to 4 Tx/Rx                                |
    % +---------------------+------------------------------------------------------+
    % | Device deployment   | 80% indoor, 20% outdoor (in car), uniformly random   |
    % +---------------------+------------------------------------------------------+
    % | UE Mobility model   | Fixed speed for all UE in same mobility class.       |
    % |                     | Uniformly random directions.                         |
    % +---------------------+------------------------------------------------------+
    % | UE speeds           | Indoor: 3km/h, outdoor (in car): 30km/h              |
    % +---------------------+------------------------------------------------------+
    properties 
        Center;             %Center of the target area
        MacroCoordinates;   %Center of each macro cell
        MacroCells;              %Cell array containing all macro cell objs
        MicroCells;             %Cell array containing all micro cell objs
        PicoCells;              %Cell array containing all pico cell objs
        Radius;             %The ISD of macrocells
        NumMacro;                %The number of macro cells
        NumMicro;
        NumPico;
        MicroCoordinates;    %Coordinates of the micro BST, placed on the middle of the edges of the cell border
        PicoCoordinates;
        PosScheme;
        Param;
    end

    methods 
        function obj = NetworkLayout(xc, yc, Param)
            %Constructor functions
            %Check for positioning scheme
            switch Param.posScheme
                case '3GPP TR 38.901 UMa' % from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-1
                    obj.PosScheme = '3GPP TR 38.901 UMa';
                    Param.macroRadius = 500;
                    Param.numMacro = 19;
                    Param.numMicro = 0;
                    Param.numPico = 0;
                    Param.macroHeight = 25;
                    Param.numUsers = 30 * Param.numMacro; %Estimated, not mentioned directly
                    Param.ueHeight = 1.5;
                    %original scenario has 80% indoor users
                    %All users move with an avg of 3km/h
                    %Uniformly distributed users

                case '3GPP TR 38.901 RMa' % from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-3
                    obj.PosScheme = '3GPP TR 38.901 RMa';
                    Param.macroRadius = 1732;  % or 5000m
                    Param.numMacro = 19;
                    Param.numMicro = 0;
                    Param.numPico = 0;
                    Param.macroHeight = 35;
                    Param.numUsers = 30 * Param.numMacro;
                    Param.ueHeight = 1.5;
                    %Carrier freq: up to 7 GHz
                    %uniformly distributed users
                    %50% indoor, 50% in car


                case 'ITU-R M.2412-0 5.B.C' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.b Configuration C
                    obj.PosScheme = 'ITU-R M.2412-0 5.B.C';
                    Param.macroRadius = 200;
                    Param.numMacro = 19;
                    Param.numMicro = 9*Param.numMacro;
                    Param.numPico = 0;
                    Param.macroHeight = 25;
                    Param.microHeight = 10;
                    Param.ueHeight = 1.5;
                    Param.numUsers = 30 * Param.numMacro;
                    Param.primaryTrafficModelling = 'fullBuffer';
                    Param.trafficMix = 1;
                    %Perhaps larger building grid??
                    %Carrier frequency: 4 GHz and 30 GHz available in macro and micro layers
                    %Total transmit power per TRxP:  -Macro 4 GHz:
                                                    %   44 dBm for 20 MHz bandwidth
                                                    %   41 dBm for 10 MHz bandwidth
                                                    %-Macro 30 GHz:
                                                    %   40 dBm for 80 MHz bandwidth
                                                    %   37 dBm for 40 MHz bandwidth
                                                    %e.i.r.p. should not exceed 73 dBm
                                                    %-Micro 4 GHz:
                                                    %   33 dBm for 20 MHz bandwidth
                                                    %   30 dBm for 10 MHz bandwidth
                                                    %-Micro 30 GHz:
                                                    %   33 dBm for 80 MHz bandwidth
                                                    %   30 dBm for 40 MHz bandwidth
                                                    %e.i.r.p. should not exceed 68 dBm
                    %UE power class: 4 GHz: 23 dBm, 30 GHz: 23 dBm, e.i.r.p. should not exceed 43 dBm
                    %Percentage of high and low loss building type: 20% high loss, 80% low loss
                    %Number of antenna elements per TRxP: 256 Tx/Rx
                    %Number of UE Antenna elements: 4 GHz: Up to 8 Tx/Rx, 30 GHz: Up to 32 Tx/Rx
                    % 80% indoor, 20% outdoor (in car)
                    %Mobility modelling: Fixed and idential speed v of all UEs, random direction
                    %UE speed: indoor: 3km/h    outdoor: 30km/h (in car)
                    %BS noise figure: 4GHz -> 5dB
                                    %30GHz -> 7dB
                    %UE noise figure: 4GHz -> 7dB
                                    %30GHz -> 10dB (assumed for high performance UEs. For low performance 13 dB could be considered)
                    %Thermal noise: -174 dBm/Hz
                    %BS antenna element gain: 4GHz -> 8dBi, 30GHz -> Macro TRxP: 8dBi
                    %UE antenna element gain: 4GHz -> 0dBi, 30GHz -> 5dBi
                    %Bandwidths: 4GHz -> 20MHz for TDD or 10MHz + 10MHz for FDD
                    %           30GHz -> 80MHz for TDD or 40MHz + 40MHz for FDD
                    %UE density: 10 UEs per TRxP

                    % Table in restructuretext to try it out.
                  
                    % 
                case 'ITU-R M2412-0 5.C.A' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.c Configuration A
                    obj.PosScheme = 'ITU-R M.2412-0 5.C.A';
                    Param.macroRadius = 1732; 
                    Param.numMacro = 19;
                    Param.numMicro = 0;
                    Param.numPico = 0;
                    Param.macroHeight = 35;
                    Param.ueHeight = 1.5;
                    Param.numUsers = 30 * Param.numMacro;
                    Param.primaryTrafficModelling = 'fullBuffer';
                    Param.trafficMix = 1;
                    %Load no buildings...
                    %

                case 'Single Cell' % Deploys a single cell with 3 micro BST and randomly placed pico BST in each sector
                    obj.PosScheme = 'Single Cell';
                    Param.macroRadius = 300;
                    Param.numMacro = 1;
                    Param.numMicro = 9 * Param.numMacro;
                    Param.numPico = Param.numPicoPerSector * 3 * Param.numMacro; 
                    Param.macroHeight = 35;
                    Param.microHeight = 10;
                    Param.picoHeight = 5;
                    Param.numUsers = 15;
                    Param.ueHeight = 1.5;
                    Param.primaryTrafficModelling = 'fullBuffer';
                    Param.trafficMix = 1;

                otherwise
                    obj.PosScheme = 'None';

            end
            obj.Center = [xc yc];
            obj.Radius = Param.macroRadius;
            obj.NumMacro = Param.numMacro;
            obj.findMacroCoordinates();
            obj.generateMacroCells(Param);
            obj.findMicroCoordinates(Param);
            obj.NumMicro = length(obj.MicroCoordinates(:,1));
            obj.generateMicroCells(Param);
            obj.findPicoCoordinates(Param);
            obj.NumPico = length(obj.PicoCoordinates(:,1));
            obj.generatePicoCells(Param);
            Param.numEnodeBs=obj.NumMacro + obj.NumMicro + obj.NumPico;
            obj.Param = Param;
            
        end

        function draweNBs(obj, Param)
            % This method uses the previously calculated coordinates of all 3 kinds of cells (macro, micro, pico) and draws them on top of the building grid in the figure made from the createLayoutPlot function.
            % 
            % :input Param: Parameter struct containing the following:
            % :Param.buildings: (2-dimensional array of double) Building coordinaates defining the layout of the city.
            % :Param.LayoutAxes: Axes to plot on defined in createLayoutPlot
            %
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
                xc = obj.MacroCells{i}.Center(1);
                yc = obj.MacroCells{i}.Center(2);
                text(Param.LayoutAxes,xc,yc-20,strcat('Macro BS ', num2str(obj.MacroCells{i}.CellID), ' (',num2str(round(xc)),', ',num2str(round(yc)),')'),'HorizontalAlignment','center');
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
                    cHex = [(xc + obj.MacroCells{1}.CellRadius * cos((i-1)*2*theta)) ...
                            (yc + obj.MacroCells{1}.CellRadius * sin((i-1)*2*theta))];
                    for j=1:7
                        xyHex(j,1) = cHex(1) + obj.MacroCells{1}.CellRadius*cos(j*theta);
                        xyHex(j,2) = cHex(2) + obj.MacroCells{1}.CellRadius*sin(j*theta);
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

                xr = obj.MicroCoordinates(i,1);
                yr = obj.MicroCoordinates(i,2);

                f = imagesc(Param.LayoutAxes,[xr-microLengthX xr+microLengthX],[yr-microLengthY yr+microLengthY],microImg);
                set(f, 'AlphaData', alpha);
                
                text(xr,yr+20,strcat('Micro BS ', num2str(obj.MicroCells{i}.CellID),' (',num2str(round(xr)),', ', ...
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
                text(x,y+20,strcat('Pico BS ', num2str(obj.PicoCells{i}.CellID),' (',num2str(round(x)),', ', ...
                    num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
                        
                f = imagesc(Param.LayoutAxes,[x-picoLengthX x+picoLengthX],[y-picoLengthY y+picoLengthY],picoImg);
                set(f, 'AlphaData', alpha);
                drawnow
                
        
            end
        end
    end

    methods (Access = private)

        function obj = findMacroCoordinates(obj)
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
        function obj = generateMacroCells(obj,Param)
            cells = cell(obj.NumMacro,1);
            for i=1:obj.NumMacro
                cells(i)={MacroCell(obj.MacroCoordinates(i,1),obj.MacroCoordinates(i,2),Param,i)};
            end
            obj.MacroCells = cells;
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
                        microCenters(iMicro,:) = obj.MacroCells{iMacro}.MicroPos(i,:);
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

        %Generate MicroCells objects 
        function obj = generateMicroCells(obj,Param)
            cells = cell(obj.NumMicro,1);
            for i=1:obj.NumMicro
                cells(i)={MicroCell(obj.MicroCoordinates(i,1),obj.MicroCoordinates(i,2),Param,(i+obj.MacroCells{obj.NumMacro}.CellID))};
            end
            obj.MicroCells = cells;
        end

        %Find the coordinates of all picocells in all macrocells
        function obj = findPicoCoordinates(obj,Param)
            %Place pico stations at potential positions until all are placed
            picoCenters = zeros(Param.numPico,2);
            iPico = 1;
            picoTrack = ones(obj.NumMacro,1);
            while iPico <= Param.numPico
                for i=1:obj.NumMacro

                    for j=picoTrack(i):picoTrack(i) +2
                        picoCenters(iPico,:) = obj.MacroCells{i}.PicoPos(j,:);
                        if iPico +1 > Param.numPico
                            picoTrack(:) = 0;
                            iPico = iPico +1;
                            break
                        end
                        iPico = iPico +1;
                        picoTrack(i) = picoTrack(i)+1;
                    end

                    if picoTrack(1) == 0
                        break
                    end

                end
            end

            obj.PicoCoordinates = picoCenters;

        end

        %Generate the PicoCells objects
        function obj = generatePicoCells(obj,Param)
            cells = cell(obj.NumPico,1);

            if obj.NumMicro <1 
                n = obj.NumMacro;
            else
                n = obj.MicroCells{obj.NumMicro}.CellID;
            end
            for i=1:obj.NumPico
                cells(i)={PicoCell(obj.PicoCoordinates(i,1),obj.PicoCoordinates(i,2),Param, (i+n))};
            end
            obj.PicoCells = cells;
        end

    end

end