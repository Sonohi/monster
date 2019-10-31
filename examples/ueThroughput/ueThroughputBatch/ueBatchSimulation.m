function ueBatchSimulation(simulationChoice, folderPath)
	% Single instance of simulation for the UE throughput example
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
	elseif simulationChoice == 3
		choice = 'withMicro';
	elseif simulationChoice == 4
		choice = 'withoutBackhaul';
	elseif simulationChoice == 5
		choice = 'withBackhaul';
	end

	% Get configuration
	Config = MonsterConfig();

	% Setup configuration for scenario
	Config.Logs.logToFile = 1;
	Config.Logs.logFile = strcat(Config.Logs.logPath, datestr(datetime, ...
		Config.Logs.dateFormat), '_choice_', choice, '.log');
	Config.Logs.logLevel = 'NFO';
	%Set number of rounds
	Config.Runtime.simulationRounds = 100; 
	%Disable plotting
	Config.SimulationPlot.runtimePlot = 0;
	%Setup numbers of UEs
	Config.Ue.number = 25;
	%Setup number of Macro eNodeB
	Config.MacroEnb.sitesNumber = 1;
	Config.MacroEnb.cellsPerSite = 3;
	%Set channel conditions
	Config.Channel.fadingActive = 'false';
	Config.Channel.losMethod = 'NLOS';
	%Set bandwidth
	if simulationChoice == 2
		Config.MacroEnb.numPRBs = 100; %Double prb
	else
		Config.MacroEnb.numPRBs = 50; %baseline
	end 
	%Set number of micro basestation
	if simulationChoice == 3
		Config.MicroEnb.sitesNumber = 3; %1 per cell
	else
		Config.MicroEnb.sitesNumber = 0; %baseline
	end
	%Set traffic to fullbuffer
	Config.Traffic.arrivalDistribution = 'Static';
	Config.Traffic.primary = 'fullBuffer';
	Config.Traffic.mix = 0;
	if simulationChoice == 4
		Config.Backhaul.backhaulOn = 0; % Backhaul off
	else
		Config.Backhaul.backhaulOn = 1; % Backhaul on
	end

	if simulationChoice == 5
		Config.Backhaul.bandwidth = 10^7; %backhaul bottleneck
	else
		Config.Backhaul.bandwidth = 10^9; %Backhaul not a bottleneck
	end

	Config.Mobility.scenario = 'pedestrian';

	Logger = MonsterLog(Config);

	% Create a simulation object 
	Simulation = Monster(Config, Logger);

	for iRound = 0:(Simulation.Runtime.totalRounds - 1)
		Simulation.setupRound(iRound);
	
		Simulation.Logger.log(sprintf('(MAIN) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Runtime.currentRound, Simulation.Runtime.currentTime, ...
		Simulation.Runtime.remainingTime ), 'NFO');	
		
		Simulation.run();
	
		Simulation.Logger.log(sprintf('(MAIN) completed simulation round %i. %i rounds left' ,....
		Simulation.Runtime.currentRound, Simulation.Runtime.remainingRounds), 'NFO');
	
		Simulation.collectResults();
	
		Simulation.Logger.log('(MAIN) collected simulation round results', 'NFO');
	
		Simulation.clean();
	
		if iRound ~= Simulation.Runtime.totalRounds - 1
			Simulation.Logger.log('(MAIN) cleaned parameters for next round', 'NFO');
		else
			Simulation.Logger.log('(MAIN) simulation completed', 'NFO');
			% Construct the export string
			
			fileName = strcat(datestr(datetime, 'HH.MM'), choice, '.mat');
			resultsFileName = strcat(folderPath, '/', choice, '/', fileName);
			storedTraffic = struct('traffic',Simulation.Traffic);
			storedResults = struct('results',Simulation.Results);
     		save(resultsFileName, 'storedResults','storedTraffic');
		end
	end

end
