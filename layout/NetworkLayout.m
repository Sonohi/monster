classdef NetworkLayout < matlab.mixin.Copyable
	%This is the class defining the layout for macro cells
	
	properties
		Terrain;							% Info about the terrain properties
		Center;             	% Center of the target area
		ISD;             			% The ISD of macrocells
		NumMacroSites;				% Number of macro sites
		MacroCellsPerSite;		% Number of macro cells per site
		MacroCoordinates;   	% Center of each macro site
		MacroCells;	        	% Array containing all macro cell obj
		MicroPosPerMacroCell;	% NUmber of available micro sites position per macro cell
		NumMicroSites;				% Number of micro sites
		MicroCellsPerSite;		% Number of micro cells per site
		MicroCells;	        	% Array containing all micro cell obj
		Scenario;
		Logger;
	end
	
	methods
		function obj = NetworkLayout(Terrain, Config, Logger)
			% Constructor 
			obj.Terrain = Terrain;
			xc = (Terrain.area(3) - Terrain.area(1))/2;
			yc = (Terrain.area(4) - Terrain.area(2))/2;
			
			obj.Center = [xc yc];
			obj.Logger = Logger;
			obj.ISD = Config.MacroEnb.ISD;
			obj.MicroPosPerMacroCell = Config.MicroEnb.microPosPerMacroCell;
			obj.NumMacroSites = Config.MacroEnb.sitesNumber;
			obj.MacroCellsPerSite = Config.MacroEnb.cellsPerSite;
			obj.computeMacroCoordinates(Config, obj.Logger);
			obj.NumMicroSites = Config.MicroEnb.sitesNumber;
			obj.MicroCellsPerSite = Config.MicroEnb.cellsPerSite;
			[obj.MacroCells, obj.MicroCells] = obj.generateCells(Config);
		end
		
		function drawScenario(obj, Config, Sites, Plot)
			% drawScenario plots the network and the cell sites in the layout
			%
			% :param obj: NetworkLayout instance
			% :param Config: MonsterConfig instance
			%	:param Sites: Array<Site> instances
			% :param Plot: Struct plotting axes
			%
			enbLabelOffsetY = 0;
			% Depending on the terrain type, draw either the buildings or the coastline
			if strcmp(Config.Terrain.type, 'city')
				enbLabelOffsetY = -20;
				buildings = obj.Terrain.buildings;
				% Draw buildings
				for i = 1:length(buildings(:,1))
					x0 = buildings(i,1);
					y0 = buildings(i,2);
					x = buildings(i,3)-x0;
					y = buildings(i,4)-y0;
					rectangle(Plot.LayoutAxes,'Position',[x0 y0 x y], ...
						'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
				end
			elseif strcmp(Config.Terrain.type, 'maritime')
				enbLabelOffsetY = 30;
				% draw coastline
				plot(Plot.LayoutAxes, Config.Terrain.coast.coastline(:,1), Config.Terrain.coast.coastline(:,2), ...
					'Color', [0.62 0.21 0.04],...
					'LineStyle', '-',...
					'LineWidth', 2, ...
					'DisplayName', 'Coastline');
				% Draw a container for the scenario
				rectangle(Plot.LayoutAxes, 'Position', Config.Terrain.area, ...
					'FaceColor',[.99 .99 .99 .1],...
					'EdgeColor',[0 0 0 0.1],...
					'LineWidth', 1.2,...
					'LineStyle', '-.');
			end
			
			% Draw the sites on the layout
			% Load images
			[macroImg, ~, macroAlpha] = imread('utils/images/macro.png');
			% For some magical reason the image is rotated 180 degrees.
			macroImg = imrotate(macroImg,180);
			macroAlpha = imrotate(macroAlpha,180);
			% Scale size of figure
			scale = 30;
			macroLengthY = length(macroImg(:,1,1))/scale;
			macroLengthX = length(macroImg(1,:,1))/scale;
			
			[microImg, ~, microAlpha] = imread('utils/images/micro.png');
			% For some magical reason the image is rotated 180 degrees.
			microImg = imrotate(microImg,180);
			microAlpha = imrotate(microAlpha,180);
			% Scale size of figure
			microLengthY = length(microImg(:,1,1))/scale;
			microLengthX = length(microImg(1,:,1))/scale;
			
			% Loop on the sites and draw depending on the class
			for iSite = 1:length(Sites)
				xc = Sites(iSite).Position(1);
				yc = Sites(iSite).Position(2);
				siteLabel = strcat('Macro site ',num2str(Sites(iSite).SiteId));
				siteImg = macroImg;
				siteImgAlpha = macroAlpha;
				siteImgLenghX = macroLengthX;
				siteImgLenghY = macroLengthY;
				cellsPerSite = Config.MacroEnb.cellsPerSite;
				cellRadius = obj.MacroCells(1).Radius;
				if strcmp(Sites(iSite).Class, 'micro')
					siteLabel = strcat('Micro site ', num2str(Sites(iSite).SiteId));
					siteImg = microImg;
					siteImgAlpha = microAlpha;
					siteImgLenghX = microLengthX;
					siteImgLenghY = microLengthY;
					cellsPerSite = Config.MicroEnb.cellsPerSite;
					cellRadius = obj.MicroCells(1).Radius;
				end
				text(Plot.LayoutAxes, xc, yc + enbLabelOffsetY, ...
					strcat(siteLabel, '(',num2str(round(xc)),', ',...
					num2str(round(yc)),')'),'HorizontalAlignment','center');
				% Position and set alpha from png image
				f = imagesc(Plot.LayoutAxes,[xc - siteImgLenghX xc + siteImgLenghX], ...
					[yc - siteImgLenghY yc + siteImgLenghY], siteImg);
				set(f, 'AlphaData', siteImgAlpha);
				
				% Now draw the cells boundaries for the site (only if macro
				% site)
				if strcmp(Sites(iSite).Class, 'macro')
					theta = pi/cellsPerSite;
					xyHex = zeros(7,2);
					for i=1:cellsPerSite
						cHex = [(xc + cellRadius * cos((i-1)*2*theta)) ...
							(yc + cellRadius * sin((i-1)*2*theta))];
						for j=1:7
							xyHex(j,1) = cHex(1) + cellRadius*cos(j*theta);
							xyHex(j,2) = cHex(2) + cellRadius*sin(j*theta);
						end
						l = line(Plot.LayoutAxes,xyHex(:,1),xyHex(:,2), 'Color', 'k');
						set(get(get(l,'Annotation'),'LegendInformation'),'IconDisplayStyle','off')
					end
				end
			end
			
		end
		
		function drawUes(~, Users, Config, Logger, Plot)
			% drawUes plots the Users in the plot layout
			%
			% :param obj: NetworkLayout instance
			%	:param Users: Array<UserEquipment> instances
			% :param Config: MonsterConfig instance
			% :param Logger: MonsterLog instance
			% :param Plot: Struct plotting axes
			%
			
			if strcmp(Config.Terrain.type, 'city')
				for iUser = 1:length(Users)
					x0 = Users(iUser).Position(1);
					y0 = Users(iUser).Position(2);
					
					% UE in initial position
					plot(Plot.LayoutAxes,x0, y0, ...
						'Marker', Users(iUser).PlotStyle.marker, ...
						'MarkerFaceColor', Users(iUser).PlotStyle.colour, ...
						'MarkerEdgeColor', Users(iUser).PlotStyle.edgeColour, ...
						'MarkerSize',  Users(iUser).PlotStyle.markerSize, ...
						'DisplayName', strcat('UE ', num2str(Users(iUser).NCellID)));
					
					% Trajectory
					plot(Plot.LayoutAxes,Users(iUser).Mobility.Trajectory(:,1), Users(iUser).Mobility.Trajectory(:,2), ...
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
					
					f = imagesc(Plot.LayoutAxes, [x0 - shipLengthX x0 + shipLengthX],...
						[y0 - shipLengthY y0 + shipLengthY], shipImg);
					set(f, 'AlphaData', alpha);
					
					% Trajectory
					plot(Plot.LayoutAxes, Users(iUser).Mobility.Trajectory(:,1), Users(iUser).Mobility.Trajectory(:,2), ...
						'Color', [0.302 0.749 0.9294], ...
						'LineStyle', ':', ...
						'LineWidth', 1.6,...
						'DisplayName', strcat('Ship UE ', num2str(Users(iUser).NCellID), ' trajectory'));
					drawnow();
				end
				
			else
				Logger.log('(NETWORK LAYOUT - drawUes) error, unsupported terrain type', 'ERR');
				
			end
			% Toggle the legend
			legend('Location','northeastoutside')
		end
		
		function SiteConfig = getMacroSiteConfig(obj, Config, siteId)
			% Returns the configuration of a macro site and its cells for position and ID
			%
			% :param obj: NetworkLayout instance
			% :param Config: MonsterConfig instance
			% :param siteId: Integer site identifier
			%
			% :returns SiteConfig: struct with the site configuration
			
			iSiteCells = find([obj.MacroCells.SiteID] == siteId);
			siteCellsIds = [obj.MacroCells(iSiteCells).CellID];
			sitePosition = [obj.MacroCoordinates(siteId,:), Config.MacroEnb.height];
			SiteConfig = struct(...
				'id', siteId,...
				'class', 'macro',...
				'position', sitePosition,...
				'macroCellId', -1,...
				'cellsIds', siteCellsIds);
		end
		
		function SiteConfig = getMicroSiteConfig(obj, Config, iSite, Sites)
			% Returns the configuration of a micro site and its cells for position and ID
			%
			% :param obj: NetworkLayout instance
			% :param Config: MonsterConfig instance
			% :param iSite: Integer index to generate site id
			% :param Sites: Array<Site> sites created
			%
			% :returns SiteConfig: struct with the site configuration
			
			% Find corresponding macro cell
			totMacroCells = Config.MacroEnb.sitesNumber * Config.MacroEnb.cellsPerSite;
			iMacroCell = iSite - floor(iSite/totMacroCells)*totMacroCells;
			if ~iMacroCell
				iMacroCell = totMacroCells;
			end
			macroCell = obj.MacroCells(iMacroCell);
			% The microCoordinates is of size Config.MicroEnb.microPosPerMacroCell
			% We need to find how many of the micro sites positions are already used in this macro cell
			% Find cells that have set the macro cell to the current one
			iMicroCellInMacro = 1;
			allCells = [Sites.Cells];
			iCellsInMacro = find([allCells.MacroCellId] == macroCell.CellID);
			if ~isempty(iCellsInMacro)
				iMicroCellInMacro = iMicroCellInMacro + length(iCellsInMacro)/Config.MicroEnb.microPosPerMacroCell;
				% Throw an error if there are more than the allowed number
				if iMicroCellInMacro > Config.MicroEnb.microPosPerMacroCell
					obj.Logger.log("(SETUP - setupSites) exceeded maximum number of allowed micro sites per macro cell", "ERR");
				end
			end
			sitePosition = [macroCell.MicroCoordinates(iMicroCellInMacro, :), Config.MicroEnb.height];
			siteId = iSite + Config.MacroEnb.sitesNumber;
			% Now find IDS for the micro cells that can be created for this micro site
			iSiteCells = find([obj.MicroCells.SiteID] == siteId);
			siteCellsIds = [obj.MicroCells(iSiteCells).CellID];
			SiteConfig = struct(...
				'id', siteId,...
				'class', 'micro',...
				'position', sitePosition,...
				'macroCellId', macroCell.CellID,...
				'cellsIds', siteCellsIds);
		end
	end
	
	methods (Access = private)
		
		function obj = computeMacroCoordinates(obj, Config, Logger)
			centers = zeros(obj.NumMacroSites,2);
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
				if obj.NumMacroSites > 1
					centers(2,1) = obj.Center(1,1)+obj.ISD*cos(rho);
					centers(2,2) = obj.Center(1,2)+obj.ISD*sin(rho);
				end
				%Rest of the coordinates follow the same pattern, but when going out one "ring" a special action are carried out.
				for i=3:obj.NumMacroSites
					if special
						%Perform special action
						centers(i,1) = centers(i-1,1) + obj.ISD*cos(theta+rho);
						centers(i,2) = centers(i-1,2) + obj.ISD*sin(theta+rho);
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
						centers(i,1) = centers(i-1,1) + obj.ISD*cos(theta+rho);
						centers(i,2) = centers(i-1,2) + obj.ISD*sin(theta+rho);
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
				macroX = linspace(minX, maxX, obj.NumMacroSites);
				macroY = randi([round(minY), round(minY + (maxY-minY)/3)], obj.NumMacroSites, 1);
				centers(:,1) = macroX';
				centers(:,2) = macroY';
			else
				Logger.log('(NETWORK LAYOUT - computeMacroCoordinates) unsupported terrain scenario');
			end
			% Set back in object
			obj.MacroCoordinates = centers;
		end
		
		% Generate the cells instances used to provide positioning info
		function [macroCells, microCells] = generateCells(obj,Config)
			% Initialise
			macroSiteCount = 0;
			macroCellCount = 0;
			microSiteCount = obj.NumMacroSites;
			microCellCount = 0;
			for iMacroSite = 1:obj.NumMacroSites
				macroSiteCount = macroSiteCount + 1;
				macroSiteCentre = [obj.MacroCoordinates(iMacroSite, 1), obj.MacroCoordinates(iMacroSite, 2)];
				macroCellsIds = 3*macroSiteCount + (1:obj.MacroCellsPerSite);
				macroCellsCentres = obj.calculateCellCentres(macroSiteCentre, obj.MacroCellsPerSite, Config.MacroEnb.ISD);
				for iMacroCell = 1: obj.MacroCellsPerSite
					macroCellCount = macroCellCount + 1;
					macroCellCentre = [macroCellsCentres(iMacroCell, 1), macroCellsCentres(iMacroCell, 2)];
					macroCells(macroCellCount) = MacroCell(Config, obj.Logger, macroSiteCount, macroCellCentre, macroCellsIds(iMacroCell), obj.MicroPosPerMacroCell);
					% At this point the macro cell instance includes also the available positions for the centres of the micro sites
					microSitesCentres = macroCells(macroCellCount).MicroCoordinates;
					% Now generate the micro cells for each micro site
					for iMicroSite = 1:length(microSitesCentres)
						microSiteCount = microSiteCount + 1;
						% Generate IDs for the micro cells of this micro site
						microSiteCentre = [microSitesCentres(iMicroSite, 1), microSitesCentres(iMicroSite, 2)];
						microCellsIds = 3*microSiteCount + (1:obj.MicroCellsPerSite);
						microCellsCentres = obj.calculateCellCentres(microSiteCentre, obj.MicroCellsPerSite, Config.MicroEnb.ISD);
						for iMicroCell = 1:obj.MicroCellsPerSite
							microCellCount = microCellCount + 1;
							microCellCentre = [microCellsCentres(iMicroCell, 1), microCellsCentres(iMicroCell, 2)];
							microCells(microCellCount) = MicroCell(Config, obj.Logger, microSiteCount, microCellCentre, microCellsIds(iMicroCell));
						end
					end
				end
			end
		end
		
		% Calculates the position of the cell centres for groups of cells of the same site
		function cellsCentres = calculateCellCentres(obj, siteCentre, numCells, ISD)
			% Divide the circumference angle around the centre based on the number of cells
			theta = 2*pi/numCells;
			% The average cell radius is calculated dividing the ISD by the number of cells
			cellRadius = ISD/numCells;
			for iCell = 1:numCells
				cellsCentres(iCell, 1) = siteCentre(1) + cellRadius * cos((iCell-1)*theta);
				cellsCentres(iCell, 2) = siteCentre(2) + cellRadius * sin((iCell-1)*theta);
			end
		end
		
	end
	
end