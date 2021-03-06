clear all 
close all
%% Get configuration
Config = MonsterConfig(); % Get template config parameters

% Make local changes
Config.SimulationPlot.runtimePlot = 0;
Config.Ue.number = 1;
Config.MacroEnb.sitesNumber = 7;
Config.MacroEnb.cellsPerSite = 3;
Config.MicroEnb.sitesNumber = 0;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS'; % 'NLOS', '3GPP38901-probability', 'LOS'
Config.MacroEnb.antennaType = 'sectorised';



Logger = MonsterLog(Config);

%% Setup objects
simulation = Monster(Config, Logger);


%% Inspect Layout
H = simulation.Channel.plotSINR(simulation.Cells, simulation.Users(1), 20, simulation.Logger);
H = simulation.Channel.plotPower(simulation.Cells, simulation.Users(1), 20, simulation.Logger);
