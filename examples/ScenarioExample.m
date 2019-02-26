clear all 

% Disable cast to struct warnings
w = warning ('off','all');

%% Get configuration
Config = MonsterConfig(); % Get template config parameters
Config.Scenario.scenario = '3GPP TR 38.901 UMa' ; %Chose scenario

%% Setup objects
Simulation = Monster(Config);
%for iRound = 0:(Config.Runtime.totalRounds - 1)
 %   Simulation.setupRound(iRound);
  %  Simulation.run();
   % Simulation.collectResults();
    %Simulation.clean();

%end

