function batchSimulation(simulationSeed, sweepEnabled, folderPath)
	% Single instance of simulation for the maritime batch scenario
	%
	% :param simulationSeed: integer that sets the seed for the simulation instance
	% :param sweepEnabled: boolean that toggles whether the sweeping algorithm should be enabled in this instance
	% :param folderPath: string that represents the path of the folder where to save the results
	% 
	
	% Get configuration
	Config = MonsterConfig();

	% Setup configuration for scenario
	Config.Runtime.seed = simulationSeed;
	Config.Logs.logToFile = 1;
	Config.Logs.logFile = strcat(Config.Logs.logPath, datestr(datetime, ...
		Config.Logs.dateFormat), '_seed_', num2str(simulationSeed), '.log');
	Config.Logs.logLevel = 'NFO';
	Config.SimulationPlot.runtimePlot = 0;
	Config.Ue.number = 1;
	if sweepEnabled
		Config.Ue.antennaType = 'vivaldi';
	else 
		Config.Ue.antennaType = 'omni';
	end
	Config.MacroEnb.sitesNumber = 3;
	Config.MacroEnb.cellsPerSite = 1;
	Config.MicroEnb.sitesNumber = 0;
	Config.Mobility.scenario = 'maritime';
	Config.Phy.uplinkFrequency = 1747.5;
	Config.Phy.downlinkFrequency = 2600;
	Config.Harq.active = false;
	Config.Arq.active = false;
	Config.Channel.shadowingActive = 0;
	Config.Channel.losMethod = 'NLOS';
	Config.Traffic.arrivalDistribution = 'Static';
	Config.Traffic.static = Config.Runtime.totalRounds * 10e3; % No traffic

	Logger = MonsterLog(Config);
	Logger.log('(MARITIME SWEEP) configured simulations and started initialisation', 'NFO');

	% Create a simulation object 
	Simulation = Monster(Config, Logger);

	% Set default bearing 
	Simulation.Users.Rx.AntennaArray.Bearing = 180;

	% Create the maritime sweep specific data structure to store the state
	% Choose on which metric to optimise teh sweep: power or sinr
	sweepParameters = generateSweepParameters(Simulation, 'power');

	Simulation.Logger.log('(MARITIME SWEEP) sweep parameters initialised', 'NFO');

	for iRound = 0:(Config.Runtime.totalRounds - 1)
		Simulation.setupRound(iRound);

		Simulation.Logger.log(sprintf('(MARITIME SWEEP) simulation round %i, time elapsed %f s, time left %f s',...
			Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
			Simulation.Config.Runtime.remainingTime ), 'NFO');	
		
		Simulation.run();

		% Perform sweep
		Simulation.Logger.log('(MARITIME SWEEP) simulation starting sweep algorithm', 'NFO');
		if sweepEnabled
			sweepParameters = performAntennaSweep(Simulation, sweepParameters);
		end

		Simulation.Logger.log(sprintf('(MARITIME SWEEP) completed simulation round %i. %i rounds left' ,....
			Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

		Simulation.collectResults();

		Simulation.Logger.log('(MARITIME SWEEP) collected simulation round results', 'NFO');

		Simulation.clean();

		if iRound ~= Config.Runtime.totalRounds - 1
			Simulation.Logger.log('(MARITIME SWEEP) cleaned parameters for next round', 'NFO');
		else
			Simulation.Logger.log('(MARITIME SWEEP) simulation completed', 'NFO');
			% Construct the export string
			basePath = strcat('results/maritime/', datestr(datetime, 'yyyy.mm.dd'));
			fileName = strcat(datestr(datetime, 'HH.MM'), '_seed_', num2str(Config.Runtime.seed), '.mat');
			subFolder = 'no_sweep';
			if sweepEnabled
				subFolder = 'sweep';
			end
			resultsFileName = strcat(basePath, '/', subFolder, '/', fileName);
			storedResults = struct('sinr', Simulation.Results.wideBandSinrdB, 'power', Simulation.Results.receivedPowerdBm, 'config', Simulation.Config);
			
			if ~exist(folderPath, 'dir')
				mkdir(folderPath);
				mkdir(strcat(folderPath, '/no_sweep'));
				mkdir(strcat(folderPath, '/sweep'));
			end
			save(resultsFileName, 'storedResults');
		end
	end

end
