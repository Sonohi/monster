%
% Maritime sweep scenario
%

% Antenna sweep algorithm parameters
hysteresisTimer = 0;
rotationIncrement = 90;
currentAngle = 0;
maxAngle = 360;

% Get configuration
Config = MonsterConfig();

% Setup configuration for scenario
Config.SimulationPlot.runtimePlot = 1;
Config.Ue.number = 1;
Config.Ue.antennaType = 'vivaldi';
Config.MacroEnb.number = 3;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;
Config.Mobility.scenario = 'maritime'
Config.Phy.uplinkFrequency = 1747.5;
Config.Phy.downlinkFrequency = 1842.5;
Config.Harq.active = false;
Config.Arq.active = false;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS';

% Create a simulation object 
Simulation = Monster(Config);

for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);

	monsterLog(sprintf('(MAIN) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
		Simulation.Config.Runtime.remainingTime ), 'NFO');	
	
	Simulation.run();

	monsterLog(sprintf('(MAIN) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

	Simulation.collectResults();

	monsterLog('(MAIN) collected simulation round results', 'NFO');

	Simulation.clean();

	if iRound ~= Config.Runtime.totalRounds - 1
		monsterLog('(MAIN) cleaned parameters for next round', 'NFO');
	else
		monsterLog('(MAIN) simulation completed', 'NFO');
	end
end