clear all 
close all
%% Get configuration
Config = MonsterConfig(); % Get template config parameters

% Make local changes
Config.SimulationPlot.runtimePlot = 0;
Config.Ue.number = 1;
Config.MacroEnb.number = 7;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS';

%% Setup objects
Config.setupNetworkLayout();
Stations = setupStations(Config);
Users = setupUsers(Config);
Channel = setupChannel(Stations, Users, Config);
Channel.extraSamplesArea = 500;
[Traffic, Users] = setupTraffic(Users, Config);

%% Inspect Layout
H = Channel.plotSINR(Stations, Users(1), 10);