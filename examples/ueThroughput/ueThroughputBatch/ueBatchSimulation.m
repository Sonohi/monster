function ueBatchSimulation(simulationChoice, folderPath)
	% Single instance of simulation for the maritime batch scenario
	%
	% :param simulationSeed: integer that sets the seed for the simulation instance
	% :param sweepEnabled: boolean that toggles whether the sweeping algorithm should be enabled in this instance
	% :param folderPath: string that represents the path of the folder where to save the results
	% 
	
	%Find choice for simulation
	if simulationChoice == 1
		choice = 'baseline';
	elseif simulationChoice ==2
		choice = 'bandwidth';
	elseif simulationChoice ==3
		choice = 'fewUsers';
	elseif simulationChoice == 4
		choice = 'withMicro';
	end

	% Get configuration
	Config = MonsterConfig();

	% Setup configuration for scenario
	Config.Logs.logToFile = 1;
	Config.Logs.logFile = strcat(Config.Logs.logPath, datestr(datetime, ...
		Config.Logs.dateFormat), '_choice_', choice, '.log');
	Config.Logs.logLevel = 'NFO';
	%Set number of rounds
	Config.Runtime.totalRounds = 100;
	Config.Runtime.remainingRounds = Config.Runtime.totalRounds;
	Config.Runtime.remainingTime = Config.Runtime.totalRounds*10e-3;
	Config.Runtime.realTimeRemaining = Config.Runtime.totalRounds*10;
	%Disable plotting
	Config.SimulationPlot.runtimePlot = 0;
	%Setup numbers of UEs
	if simulationChoice == 3
		Config.Ue.number = 5;
	else
		Config.Ue.number = 20;
	end
	%Setup number of Macro eNodeB
	Config.MacroEnb.sitesNumber = 1;
	Config.MacroEnb.cellsPerSite = 3;
	%Set bandwidth
	if simulationChoice == 2
		Config.MacroEnb.numPRBs = 100; %Double prb
	else
		Config.MacroEnb.numPRBs = 50; %baseline
	end 
	%Set number of micro basestation
	if simulationChoice == 4
		Config.MicroEnb.sitesNumber = 3;
	else
		Config.MicroEnb.sitesNumber = 0;
	end
	%Set traffic to fullbuffer
	Config.Traffic.arrivalDistribution = 'Static';
	Config.Traffic.primary = 'fullBuffer';
	Config.Traffic.mix = 0;

	Config.Mobility.scenario = 'pedestrian';

	Logger = MonsterLog(Config);

	% Create a simulation object 
	Simulation = Monster(Config, Logger);

	for iRound = 0:(Config.Runtime.totalRounds - 1)

		Simulation.setupRound(iRound);

		Simulation.Logger.log(sprintf('(MAIN) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
		Simulation.Config.Runtime.remainingTime ), 'NFO');	
	
		Simulation.run();

		Simulation.Logger.log(sprintf('(MAIN) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

		Simulation.collectResults();

		Simulation.Logger.log('(MAIN) collected simulation round results', 'NFO');

		Simulation.clean();

		if iRound ~= Config.Runtime.totalRounds - 1
			Simulation.Logger.log('(MAIN) cleaned parameters for next round', 'NFO');
		else
			Simulation.Logger.log('(MAIN) simulation completed', 'NFO');
			% Construct the export string
			
			fileName = strcat(datestr(datetime, 'HH.MM'), '_choice_', choice, '.mat');
			resultsFileName = strcat(folderPath, '/', choice, '/', fileName);
			storedResults = struct('results', Simulation.Results);
			
			save(resultsFileName, 'storedResults');
		end
	end

end
