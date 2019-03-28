%
% Maritime sweep scenario
%
close all;
clear all;
monsterLog('(MARITIME SWEEP) starting simulation', 'NFO');

% Get configuration
Config = MonsterConfig();

% Setup configuration for scenario
Config.SimulationPlot.runtimePlot = 1;
Config.Ue.number = 1;
Config.Ue.antennaType = 'vivaldi';
Config.MacroEnb.number = 3;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;
Config.Mobility.scenario = 'maritime';
Config.Phy.uplinkFrequency = 1747.5;
Config.Phy.downlinkFrequency = 2600;
Config.Harq.active = false;
Config.Arq.active = false;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS';
Config.Traffic.arrivalDistribution = 'Static';
Config.Traffic.static = Config.Runtime.totalRounds * 10e3; % No traffic

monsterLog('(MARITIME SWEEP) simulation configuration generated', 'NFO');

% Create a simulation object 
Simulation = Monster(Config);

% Create the maritime sweep specific data structure to store the state
sweepParameters = generateSweepParameters(Simulation);

monsterLog('(MARITIME SWEEP) sweep parameters initialised', 'NFO');

for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);

	monsterLog(sprintf('(MARITIME SWEEP) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
		Simulation.Config.Runtime.remainingTime ), 'NFO');	
	
	Simulation.run();

	% Perform sweep
	monsterLog('(MARITIME SWEEP) simulation starting sweep algorithm', 'NFO');
	sweepParameters = performAntennaSweep(Simulation, sweepParameters);

	monsterLog(sprintf('(MARITIME SWEEP) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

	Simulation.collectResults();

	monsterLog('(MARITIME SWEEP) collected simulation round results', 'NFO');

	Simulation.clean();

	if iRound ~= Config.Runtime.totalRounds - 1
		monsterLog('(MARITIME SWEEP) cleaned parameters for next round', 'NFO');
	else
		monsterLog('(MARITIME SWEEP) simulation completed', 'NFO');
	end
end