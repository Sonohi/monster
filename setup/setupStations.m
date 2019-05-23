function Stations = setupStations (Config, Logger)
	% setupStations - performs the necessary setup for the eNodeBs in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Stations: Array<EvolvedNodeB> simulation eNodeBs class instances
	
	
	% Setup macro
	Logger.log('(SETUP - setupStations) setting up macro eNodeBs', 'DBG');
	rangeA = 1;
	rangeB = Config.MacroEnb.number;
	Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'macro', x, Logger), rangeA:rangeB);
	for iStation = rangeA:rangeB
		Stations(iStation).Position = [Config.Plot.Layout.MacroCoordinates(iStation,:), Config.MacroEnb.height];
	end

	% Setup micro
	if Config.MicroEnb.number > 0
		Logger.log('(SETUP - setupStations) setting up micro eNodeBs', 'DBG');
		rangeA = Config.MacroEnb.number + 1;
		rangeB = Config.MicroEnb.number + Config.MacroEnb.number;
		Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'micro', x, Logger), rangeA:rangeB);
		ii = 1;
		for iStation = rangeA:rangeB
			Stations(iStation).Position = [Config.Plot.Layout.MicroCoordinates(ii,:), Config.MicroEnb.height];
			ii =+ 1;
		end
	end
	
	
	% Setup pico
	if Config.PicoEnb.number > 0 
% 	Logger.log('(SETUP - setupStations) setting up pico eNodeBs', 'DBG');
% 	rangeA = Config.MacroEnb.number + Config.MicroEnb.number + 1;
% 	rangeB = Config.MacroEnb.number + Config.MicroEnb.number + Config.PicoEnb.number;
% 	Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'pico', x, Logger), rangeA:rangeB);
% 	
% 	ii = 1;
% 	for iStation = rangeA:rangeB
% 			Stations(iStation).Position = [Config.Plot.Layout.Cells{1}.PicoCoordinates(ii,:), Config.PicoEnb.height];
% 			ii =+ 1;
% 	end
	end
	% Setup neighbour relationships
	% TODO revise with multiple macro base stations
	% Logger.log('(SETUP - setupStations) setting up eNodeBs neighbours', 'DBG');
	% arrayfun(@(x)x.setNeighbours(Stations, Config), Stations);
end
	