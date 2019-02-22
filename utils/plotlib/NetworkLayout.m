classdef NetworkLayout < matlab.mixin.Copyable
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
		Scenario;
	end
	
	methods
		function obj = NetworkLayout(xc, yc, Config)
			%Constructor functions
			%Scenario handler
			%Check for scenario
            switch Config.Scenario.scenario
			case '3GPP TR 38.901 UMa' 
				% from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-1 and table 7.5-6 on UMa
				obj.Scenario = '3GPP TR 38.901 UMa';
				Config.MacroEnb.radius = 500;
				Config.MacroEnb.number = 19;
				Config.MicroEnb.number = 0;
				Config.PicoEnb.number = 0;
				Config.MacroEnb.height= 25;
				Config.Ue.number = 30 * Config.MacroEnb.number; %Estimated, not mentioned directly
				Config.Ue.height = 1.5;
				Config.Channel.shadowingActive = 0;
				Config.Channel.losMethod = 'NLOS';
				%All users move with an avg of 3km/h
				Config.Mobility.scenario = 'pedestrian';
				Config.Mobility.Velocity = 0.8333; %0.8333[m/s]=3[km/h]
				%Uniformly distributed users
				%original scenario has 80% indoor users
				%Minimum distance to BS = 35m

			case '3GPP TR 38.901 RMa' % from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-3
				obj.Scenario = '3GPP TR 38.901 RMa';
				Config.MacroEnb.radius = 1732;  % or 5000m
				Config.MacroEnb.number = 19;
				Config.MicroEnb.number = 0;
				Config.PicoEnb.number = 0;
				Config.MacroEnb.height= 35;
				Config.Ue.number = 30 * Config.MacroEnb.number;
				Config.Ue.height = 1.5;
				%Carrier freq: up to 7 GHz
				%uniformly distributed users
				%50% indoor, 50% in car


			case 'ITU-R M.2412-0 5.B.C' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.b Configuration C
				obj.Scenario = 'ITU-R M.2412-0 5.B.C';
				Config.MacroEnb.radius = 200;
				Config.MacroEnb.number = 19;
				Config.MicroEnb.number = 9*Config.MacroEnb.number;
				Config.PicoEnb.number = 0;
				Config.MacroEnb.height= 25;
				Config.microHeight = 10;
				Config.Ue.height = 1.5;
				Config.Ue.number = 30 * Config.MacroEnb.number;
				Config.Traffic.primary = 'fullBuffer';
				Config.Traffic.mix = 0; %0 mix, means only primary mode
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
				obj.Scenario = 'ITU-R M.2412-0 5.C.A';
				Config.MacroEnb.radius = 1732; 
				Config.MacroEnb.number = 19;
				Config.MicroEnb.number = 0;
				Config.PicoEnb.number = 0;
				Config.MacroEnb.height= 35;
				Config.Ue.height = 1.5;
				Config.Ue.number = 30 * Config.MacroEnb.number;
				Config.Traffic.primary = 'fullBuffer';
				Config.Traffic.mix = 1;
				%Load no buildings...
				%

			case 'Single Cell' % Deploys a single cell with 3 micro BST and randomly placed pico BST in each sector
				obj.Scenario = 'Single Cell';
				Config.MacroEnb.radius = 300;
				Config.MacroEnb.number = 1;
				Config.MicroEnb.number = 0;
				Config.PicoEnb.number = 0; 
				Config.MacroEnb.height= 35;
				Config.microHeight = 10;
				Config.picoHeight = 5;
				Config.Ue.number = 1;
				Config.Ue.height = 1.5;
				Config.Traffic.primary = 'fullBuffer';
				Config.Traffic.mix = 0;

			otherwise
				obj.Scenario = 'None';

			end

			obj.Center = [xc yc];
			obj.Radius = Config.MacroEnb.radius;
			obj.NumMacro = Config.MacroEnb.number;
			obj.computeMacroCoordinates();
			obj.generateCells(Config);
			obj.findMicroCoordinates(Config);
			obj.findPicoCoordinates(Config);
			obj.NumMicro = length(obj.MicroCoordinates(:,1));
			obj.NumPico = length(obj.PicoCoordinates(:,1));
		end
		
		function draweNBs(obj, Config)
			buildings = Config.Terrain.buildings;
			
			%Find simulation area
			area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
				max(buildings(:, 4))];
			
			% Draw grid first
			
			for i = 1:length(buildings(:,1))
				x0 = buildings(i,1);
				y0 = buildings(i,2);
				x = buildings(i,3)-x0;
				y = buildings(i,4)-y0;
				rectangle(Config.Plot.LayoutAxes,'Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
			end
			
			%Draw macros
			for i=1:obj.NumMacro
				xc = obj.Cells{i}.Center(1);
				yc = obj.Cells{i}.Center(2);
				text(Config.Plot.LayoutAxes,xc,yc-20,strcat('Macro BS (',num2str(round(xc)),', ',num2str(round(yc)),')'),'HorizontalAlignment','center');
				[macroImg, ~, alpha] = imread('utils/images/macro.png');
				% For some magical reason the image is rotated 180 degrees.
				macroImg = imrotate(macroImg,180);
				alpha = imrotate(alpha,180);
				% Scale size of figure
				scale = 30;
				macroLengthY = length(macroImg(:,1,1))/scale;
				macroLengthX = length(macroImg(1,:,1))/scale;
				% Position and set alpha from png image
				f = imagesc(Config.Plot.LayoutAxes,[xc-macroLengthX xc+macroLengthX],[yc-macroLengthY yc+macroLengthY],macroImg);
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
					
					l = line(Config.Plot.LayoutAxes,xyHex(:,1),xyHex(:,2), 'Color', 'k');
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
				% 	monsterLog(strcat('Warning! Too high interferrence detected between macro and micro BST at',num2str(microPos(i,1)),',',num2str(microPos(i,2))),'WRN');
				% end
				xr = obj.MicroCoordinates(i,1);
				yr = obj.MicroCoordinates(i,2);
				
				f = imagesc(Config.Plot.LayoutAxes,[xr-microLengthX xr+microLengthX],[yr-microLengthY yr+microLengthY],microImg);
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
				
				f = imagesc(Config.Plot.LayoutAxes,[x-picoLengthX x+picoLengthX],[y-picoLengthY y+picoLengthY],picoImg);
				set(f, 'AlphaData', alpha);
				drawnow
				
			end
		end
		
		function drawUes(~, Users, Config)
			% drawUes plots the Users in the plot layout
			%
			% :obj: NetworkLayout instance
			%	:Users: Array<UserEquipment> instances
			% :Config: MonsterConfig instance
			%
			
			for iUser = 1:length(Users)
				x0 = Users(iUser).Position(1);
				y0 = Users(iUser).Position(2);
				
				% UE in initial position
				plot(Config.Plot.LayoutAxes,x0, y0, ...
					'Marker', Users(iUser).PlotStyle.marker, ...
					'MarkerFaceColor', Users(iUser).PlotStyle.colour, ...
					'MarkerEdgeColor', Users(iUser).PlotStyle.edgeColour, ...
					'MarkerSize',  Users(iUser).PlotStyle.markerSize, ...
					'DisplayName', strcat('UE ', num2str(Users(iUser).NCellID)));
				
				% Trajectory
				plot(Config.Plot.LayoutAxes,Users(iUser).Mobility.Trajectory(:,1), Users(iUser).Mobility.Trajectory(:,2), ...
					'Color', Users(iUser).PlotStyle.colour, ...
					'LineStyle', '--', ...
					'LineWidth', Users(iUser).PlotStyle.lineWidth,...
					'DisplayName', strcat('UE ', num2str(Users(iUser).NCellID), ' trajectory'));
				drawnow();
			end
			
			% Toggle the legend
			legend('Location','northeastoutside')
		end

		function Plot(obj, Simulation)
			[Simulation.Config.Plot.LayoutFigure, Simulation.Config.Plot.LayoutAxes] = createLayoutPlot(Simulation.Config);
			obj.draweNBs(Simulation.Config);
			obj.drawUes(Simulation.Users, Simulation.Config);
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
		function obj = generateCells(obj,Config)
			cells = cell(obj.NumMacro,1);
			for i=1:obj.NumMacro
				cells(i)={MacroCell(obj.MacroCoordinates(i,1),obj.MacroCoordinates(i,2),Config,i)};
			end
			obj.Cells = cells;
		end
		
		%Find the coordinates of all microcells in all macrocells
		function obj = findMicroCoordinates(obj,Config)
			
			microCenters = zeros(Config.MicroEnb.number,2);
			iMicro = 1;
			iMacro = 1;
			while iMicro <= Config.MicroEnb.number && iMacro <= obj.NumMacro
				for i=1:9 %up to 9 positions per macro site
					
					%Find the micro stations that are actually set up, e.i. more than 9 micro stations pr macro site is not supported
					if iMicro <= Config.MicroEnb.number
						microCenters(iMicro,:) = obj.Cells{iMacro}.MicroPos(i,:);
						iMicro = iMicro +1 ;
					end
				end
				iMacro = iMacro +1;
			end
			%informs if microstations were unable to be placed
			if iMicro-1 < Config.MicroEnb.number
				monsterLog(strcat('Cannot place the last  ', num2str(Config.MicroEnb.number-(iMicro-1)),' micro BST.'),'WRN');
			end
			obj.MicroCoordinates = microCenters(1:iMicro-1,:);
		end
		
		%Find the coordinates of all picocells in all macrocells
		function obj = findPicoCoordinates(obj,Config)
			
			picoCenters = zeros(Config.PicoEnb.number,2);
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