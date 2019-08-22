%
% Maritime sweep scenario
%
close all;

% Get configuration
Config = MonsterConfig();

% Setup configuration for scenario
Config.SimulationPlot.runtimePlot = 0;
Config.Logs.logLevel = 'WRN';
Config.Ue.number = 1;
Config.Ue.antennaType = 'vivaldi';
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
Simulation.Logger.log('(MARITIME SWEEP) main simulation instance created', 'NFO');

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
	sweepParameters = performAntennaSweep(Simulation, sweepParameters);

	Simulation.Logger.log(sprintf('(MARITIME SWEEP) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

	Simulation.collectResults();

	Simulation.Logger.log('(MARITIME SWEEP) collected simulation round results', 'NFO');

	Simulation.clean();

	if iRound ~= Config.Runtime.totalRounds - 1
		Simulation.Logger.log('(MARITIME SWEEP) cleaned parameters for next round', 'NFO');
	else
		Simulation.Logger.log('(MARITIME SWEEP) simulation completed', 'NFO');
	end
end