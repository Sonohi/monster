function Layout = setupNetworkLayout (Config, Logger)
	% setupNetworkLayout - performs the setup for the network layout 
	%
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Layout: NetworkLayout class instance

	% Setup the terrain based on the config
	Terrain = struct();
	Terrain.type = Config.Terrain.type;
	if strcmp(Terrain.type,'manhattan')
		% In the manhattan scenario, a Manhattan manhattan grid is generated based on a size parameter
		Terrain.areaSize = 500;
		Terrain.heightRange = [20,50];
		Terrain.buildingWidth = 40;
		Terrain.roadWidth = 10;
		Terrain.buildings = generateManhattanGrid(...
			Terrain.areaSize, Terrain.heightRange, Terrain.buildingWidth, Terrain.roadWidth);
		Terrain.area = [...
			min(Terrain.buildings(:, 1)), ...
			min(Terrain.buildings(:, 2)), ...
			max(Terrain.buildings(:, 3)), ...
			max(Terrain.buildings(:, 4))];
	elseif strcmp(Terrain.type,'maritime')
		% In the maritime scenario, a coastline is generated based on a coordinate file within a square area
		rng(Config.Runtime.seed);
		Terrain.coast = struct(...
			'mean', 300,...
			'spread', 10,... 
			'straightReach', 600,...
			'coastline', []...
			);
		Terrain.area = [0 0 Terrain.coast.straightReach Terrain.coast.straightReach];
		% Compute the coastline
		coastX = linspace(Terrain.area(1), Terrain.area(3), 50);
		coastY = randi([Terrain.coast.mean - Terrain.coast.spread, Terrain.coast.mean + Terrain.coast.spread], 1, 50);
		spreadX = linspace(Terrain.area(1), Terrain.area(3), 10000);
		spreadY = interp1(coastX, coastY, spreadX, 'spline');
		Terrain.coast.coastline(:,1) = spreadX(1,:);
		Terrain.coast.coastline(:,2) = spreadY(1,:);				
		Terrain.inlandDelta = [20,20]; % Minimum distance between the scenario edge and the coasline edge for placing the eNodeBs
		Terrain.seaDelta = [50, 20]; % X and Y delta from the coast to the sea for the vessel trajectory
	elseif strcmp(Terrain.type, 'geo')
		% In the case of the geo scenario, load data from provided WGS84 shape files
		roadsFileName = Config.Terrain.roadsFile;
		roadsShapeFile = shaperead(roadsFileName);
		% Extract road coordinates from the shape file
		% convert from geodesic WGS84 to ECEF
		% elevation is given as an average elevation of the area
		averageElevation = Config.Terrain.averageElevation;
		% Create geodesic ellipsoid
		wgs84 = wgs84Ellipsoid();

		for iRoad = 1: length(roadsShapeFile)
			geoLat = roadsShapeFile(iRoad).Y;
			geoLon = roadsShapeFile(iRoad).X;
			geoH = averageElevation * ones(1, length(geoLat));
			[x, y, ~] = geodetic2ecef(wgs84, geoLat, geoLon, geoH);
			roads(iRoad) = struct(...,
				'x', -x,...
				'y', y);
		end

		% Get boundaries to translate the coordinate systems
		minX = min([roads.x]);
		minY = min([roads.y]);
		for iRoad = 1 : length(roads)
			translatedRoads(iRoad) = struct(...
				'x', roads(iRoad).x - minX, ...
				'y', roads(iRoad).y - minY );
		end

		Terrain.roads = translatedRoads;
		Terrain.area = [...
			min([translatedRoads.x]), ...
			min([translatedRoads.y]), ...
			max([translatedRoads.x]), ...
			max([translatedRoads.y])];
	else
		Logger.log(sprintf('(MONSTER CONFIG - constructor) unsupported terrain scenario %s.', Terrain.type), 'ERR');
	end

	% Call the network layout constructor
	Layout = NetworkLayout(Terrain, Config, Logger);
end