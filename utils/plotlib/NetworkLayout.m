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
	end
	
	methods
		function obj = NetworkLayout(xc, yc, Config)
			%Constructor functions
			obj.Center = [xc yc];
			obj.Radius = Config.MacroEnb.radius;
			obj.NumMacro = Config.MacroEnb.number;
			obj.computeMacroCoordinates(Config);
			obj.generateCells(Config);
			obj.findMicroCoordinates(Config);
			obj.findPicoCoordinates(Config);
			obj.NumMicro = length(obj.MicroCoordinates(:,1));
			obj.NumPico = length(obj.PicoCoordinates(:,1));
		end
		
		function draweNBs(obj, Config)
			enbLabelOffsetY = 0;
			% Depending on the terrain type, check buildings or coastline
			if strcmp(Config.Terrain.type, 'city')
				enbLabelOffsetY = -20;
				buildings = Config.Terrain.buildings;
				% Draw buildings
				for i = 1:length(buildings(:,1))
					x0 = buildings(i,1);
					y0 = buildings(i,2);
					x = buildings(i,3)-x0;
					y = buildings(i,4)-y0;
					rectangle(Config.Plot.LayoutAxes,'Position',[x0 y0 x y], ...
						'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
				end
			elseif strcmp(Config.Terrain.type, 'maritime')
				enbLabelOffsetY = 30;
				% draw coastline
				plot(Config.Plot.LayoutAxes, Config.Terrain.coast.coastline(:,1), Config.Terrain.coast.coastline(:,2), ...
					'Color', [0.62 0.21 0.04],...
					'LineStyle', '-',...
					'LineWidth', 2, ...
					'DisplayName', 'Coastline');
				% Draw a container for the scenario
				rectangle(Config.Plot.LayoutAxes, 'Position', Config.Terrain.area, ...
					'FaceColor',[.99 .99 .99 .1],...
					'EdgeColor',[0 0 0 0.1],...
					'LineWidth', 1.2,...
					'LineStyle', '-.');
			end
			
			%Draw macros
			for i=1:obj.NumMacro
				xc = obj.Cells{i}.Center(1);
				yc = obj.Cells{i}.Center(2);
				text(Config.Plot.LayoutAxes, xc, yc + enbLabelOffsetY, ...
					strcat('Macro BS ', num2str(i), '(',num2str(round(xc)),', ',...
					num2str(round(yc)),')'),'HorizontalAlignment','center');
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
				if strcmp(Config.Terrain.type, 'city')
					% For the city scenario, draw 3 sectors as hexagons (flat top and bottom)
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
				drawnow();
			end
		end
		
		function drawUes(~, Users, Config)
			% drawUes plots the Users in the plot layout
			%
			% :obj: NetworkLayout instance
			%	:Users: Array<UserEquipment> instances
			% :Config: MonsterConfig instance
			%
			
			if strcmp(Config.Terrain.type, 'city')
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
			elseif strcmp(Config.Terrain.type, 'maritime')
				[shipImg, ~, alpha] = imread('utils/images/ship.png');
				% For some magical reason the image is flipped on both axes...
				shipImg = flip(shipImg, 1);
				%shipImg = flip(shipImg, 2);
				alpha = flip(alpha, 1);
				%alpha = flip(alpha, 2);
				% Scale size of figure
				scale = 10;
				shipLengthY = length(shipImg(:,1,1))/scale;
				shipLengthX = length(shipImg(1,:,1))/scale;
				for iUser = 1: length(Users)
					x0 = Users(iUser).Position(1);
					y0 = Users(iUser).Position(2);

					text(x0, y0 + 20, strcat('Ship UE ', num2str(Users(iUser).NCellID),...
							' (',num2str(round(x0)),', ',	num2str(round(y0)),')'),...
							'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Config.Plot.LayoutAxes, [x0 - shipLengthX x0 + shipLengthX],... 
						[y0 - shipLengthY y0 + shipLengthY], shipImg);
					set(f, 'AlphaData', alpha);

					% Trajectory
					plot(Config.Plot.LayoutAxes, Users(iUser).Mobility.Trajectory(:,1), Users(iUser).Mobility.Trajectory(:,2), ...
						'Color', [0.302 0.749 0.9294], ...
						'LineStyle', ':', ...
						'LineWidth', 1.6,...
						'DisplayName', strcat('Ship UE ', num2str(Users(iUser).NCellID), ' trajectory'));
					drawnow();
				end

			else 
				monsterLog('(NETWORK LAYOUT - drawUes) error, unsupported terrain type', 'ERR');

			end

			
			
			% Toggle the legend
			legend('Location','northeastoutside')
		end
	end
	
	methods (Access = private)
		
		function obj = computeMacroCoordinates(obj, Config)
			centers = zeros(obj.NumMacro,2);
			if strcmp(Config.Terrain.type,'city')
				%Computes the center coordinates by walking in hexagons around the center
				steps = 1;
				rings =1;
				theta = 2/3*pi;
				special = false;
				specialTrack = false;
				turn = true;
				rho = pi/3;
				stepTrack = 0;
				%Two first coordinates are "special" cases and are done seperately.
				centers(1,:) = obj.Center;
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
			elseif strcmp(Config.Terrain.type,'maritime')
				% In this case, the macros are placed on the northern side of the coastline 
				rng(Config.Runtime.seed);
				northCoastLimit = max(Config.Terrain.coast.coastline(:,2));
				minY = northCoastLimit + Config.Terrain.inlandDelta(2);
				maxY = Config.Terrain.area(4) - Config.Terrain.inlandDelta(2);
				minX = Config.Terrain.area(1) + Config.Terrain.inlandDelta(1);
				maxX = Config.Terrain.area(3) - Config.Terrain.inlandDelta(1);
				macroX = linspace(minX, maxX, obj.NumMacro);
				macroY = randi([round(minY), round(minY + (maxY-minY)/3)], obj.NumMacro, 1);
				centers(:,1) = macroX';
				centers(:,2) = macroY';
			else
				monsterLog('(NETWORK LAYOUT - computeMacroCoordinates) unsupported terrain scenario', 'ERR');
			end
			% Set back in object			
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