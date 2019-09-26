function Layout = setupNetworkLayout (Config, Logger)
	% setupNetworkLayout - performs the setup for the network layout 
	%
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Layout: NetworkLayout class instance

	% Setup the terrain based on the config
	Terrain = struct();
	Terrain.type = Config.Terrain.type;
	if strcmp(Terrain.type,'city')
		% In the city scenario, a Manhattan city grid is generated based on a size parameter
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
	else
		Logger.log(sprintf('(MONSTER CONFIG - constructor) unsupported terrain scenario %s.', Terrain.type), 'ERR');
	end

	% Call the network layout constructor
	Layout = NetworkLayout(Terrain, Config, Logger);
end