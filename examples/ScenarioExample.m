clear all 

% Disable cast to struct warnings
w = warning ('off','all');

%% Get configuration
Config = MonsterConfig(); % Get template config parameters
Config.Scenario.scenario = '3GPP TR 38.901 UMa';
% Make local changes to match scenarios in https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf
% Scenario described in table 7.2-1 and table 7.5-6 on UMa

% Config.SimulationPlot.runtimePlot = 0;
% Config.Ue.number = 1;
% Config.MacroEnb.number = 19; %19 sites, 3 sectors pr site
% Config.MacroEnb.radius = 500; %ISD is 500
% Config.MacroEnb.height = 35;
% Config.MicroEnb.number = 0;
% Config.PicoEnb.number = 0;
% Config.Channel.shadowingActive = 0;
% Config.Channel.losMethod = 'NLOS';

%% Setup objects
Simulation = Monster(Config);
for iRound = 0:(Config.Runtime.totalRounds - 1)
    Simulation.setupRound(iRound);
    Simulation.run();
    Simulation.collectResults();
    Simulation.clean();

end

