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
	Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'macro', x), rangeA:rangeB);
	for iStation = rangeA:rangeB
		Stations(iStation).Position = [Config.Plot.Layout.MacroCoordinates(iStation,:), Config.MacroEnb.height];
	end

	% Setup micro
	if Config.MicroEnb.number > 0
		monsterLog('(SETUP - setupStations) setting up micro eNodeBs', 'NFO');
		rangeA = Config.MacroEnb.number + 1;
		rangeB = Config.MicroEnb.number + Config.MacroEnb.number;
		Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'micro', x), rangeA:rangeB);
		ii = 1;
		for iStation = rangeA:rangeB
			Stations(iStation).Position = [Config.Plot.Layout.MicroCoordinates(ii,:), Config.MicroEnb.height];
			ii =+ 1;
		end
	end
	
	
	% Setup pico
	if Config.PicoEnb.number > 0 
% 	monsterLog('(SETUP - setupStations) setting up pico eNodeBs', 'NFO');
% 	rangeA = Config.MacroEnb.number + Config.MicroEnb.number + 1;
% 	rangeB = Config.MacroEnb.number + Config.MicroEnb.number + Config.PicoEnb.number;
% 	Stations(rangeA:rangeB) = arrayfun(@(x) EvolvedNodeB(Config, 'pico', x), rangeA:rangeB);
% 	
% 	ii = 1;
% 	for iStation = rangeA:rangeB
% 			Stations(iStation).Position = [Config.Plot.Layout.Cells{1}.PicoCoordinates(ii,:), Config.PicoEnb.height];
% 			ii =+ 1;
% 	end
	end
	% Setup neighbour relationships
	% TODO revise with multiple macro base stations
	% monsterLog('(SETUP - setupStations) setting up eNodeBs neighbours', 'NFO');
	% arrayfun(@(x)x.setNeighbours(Stations, Config), Stations);
end
	