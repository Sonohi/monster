function Stations = setupStations (Config)
	% setupStations - performs the necessary setup for the eNodeBs in the simulation
	%	
	% Syntax: Stations = setupStations(Config)
	% Parameters:
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Stations: (Array<EvolvedNodeB>) simulation eNodeBs class instances
	
	% Setup macro
	monsterLog('(SETUP - setupStations) setting up macro eNodeBs', 'NFO');
	rangeA = 1;
	rangeB = Config.MacroEnb.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'macro', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Config.Plot.Layout.MacroCoordinates(rangeA:rangeB,:), Config.MacroEnb.height];

	% Setup micro
	monsterLog('(SETUP - setupStations) setting up micro eNodeBs', 'NFO');
	rangeA = Config.MacroEnb.number + 1;
	rangeB = Config.MicroEnb.number + Config.MacroEnb.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'micro', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Config.Plot.Layout.Cells{1}.MicroPos(1:Config.MicroEnb.number,:), Config.MicroEnb.height];

	% Setup pico
	monsterLog('(SETUP - setupStations) setting up pico eNodeBs', 'NFO');
	rangeA = Config.MacroEnb.number + Config.MicroEnb.number + 1;
	rangeB = Config.MacroEnb.number + Config.MicroEnb.number + Config.PicoEnb.number;
	Stations(rangeA:rangeB) = EvolvedNodeB(Config, 'pico', rangeA:rangeB);
	Stations(rangeA:rangeB).Position = [...
		Config.Plot.Layout.Cells{1}.PicoPos(1:Config.PicoEnb.number,:), Config.PicoEnb.height];

	% Setup neighbour relationships
	% TODO revise with multiple macro base stations
	% monsterLog('(SETUP - setupStations) setting up eNodeBs neighbours', 'NFO');
	% arrayfun(@(x)x.setNeighbours(Stations, Config), Stations);
end
	