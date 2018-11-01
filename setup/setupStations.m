function Stations = setupStations (Config)
	% setupStations - performs the necessary setup for the eNodeBs in the simulation
	%	
	% Syntax: Stations = setupStations(Config)
	% Parameters:
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Stations: (Array<EvolvedNodeB>) simulation eNodeBs class instances
	
	% Get a network layout instance for the positioning
	xc = (Config.Terrain.area(3) - Config.Terrain.area(1))/2;
	yc = (Config.Terrain.area(4) - Config.Terrain.area(2))/2;
	Layout = NetworkLayout(xc,yc,Config); 

	% Setup macro
	monsterLog('(SETUP - setupStations) setting up macro eNodeBs', 'NFO');
	rangeA = 1;
	rangeB = Config.MacroENodeB.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'macro', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Layout.MacroCoordinates(rangeA:rangeB,:), Config.MacroENodeB.height];

	% Setup micro
	monsterLog('(SETUP - setupStations) setting up micro eNodeBs', 'NFO');
	rangeA = Config.MacroENodeB.number + 1
	rangeB = Config.MicroENodeB.number + Config.MacroENodeB.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'micro', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Layout.Cells{1}.MicroPos(rangeA:rangeB,:), Config.MicroENodeB.height];

	% Setup pico
	monsterLog('(SETUP - setupStations) creating pico', 'NFO');
	rangeA = Config.MacroENodeB.number + Config.MicroENodeB.number + 1;
	rangeB = Config.MacroENodeB.number + Config.MicroENodeB.number + Config.PicoENodeB.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'pico', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Layout.Cells{1}.PicoPos(rangeA:rangeB,:), Config.PicoENodeB.height];

	% Setup neighbour relationships
	monsterLog('(SETUP - setupStations) setting up eNodeBs neighbours', 'NFO');
	arrayfun(@(x, y, z)x.setNeighbours(y, z), Stations, Stations, Config);

	% Draw the eNodeBs
	Layout.draweNBs(Config)
end
	