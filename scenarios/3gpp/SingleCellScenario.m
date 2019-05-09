clear all 

%% Get configuration
Config = MonsterConfig(); % Get template config parameters

%add scenario specific setup for Single Cell Scenario:
% Deploys a single cell for testing purposes.
Config.Scenario = 'Single Cell';
Config.MacroEnb.ISD = 300;
Config.MacroEnb.number = 1;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0; 
Config.MacroEnb.height= 35;
Config.Ue.number = 1;
Config.Ue.height = 1.5;
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0;
%TODO: Add more specifics, to make sure, that no matter the Config, this allways works
Logger = MonsterLog(Config);

% Setup objects
Simulation = Monster(Config, Logger);
for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);
	Simulation.run();
	Simulation.collectResults();
	Simulation.clean();
end

