function [Config, Stations, Users, Channel, Traffic, Results] = setup()
% setup - performs all the task related to setting up a simulation 
%
% Syntax: [Config, Stations, Users, Traffic, Channel, Results] = setup()
% setup is called from the main file and returns the following:
%
% :Config: (MonsterConfig) simulation config class instance
% :Stations: (Array<EvolvedNodeB>) simulation eNodeBs class instances
% :Users: (Array<UserEquipment>) simulation UEs class instances
% :Channel: (Channel) simulation channel class instance
% :Traffic: (TrafficGenerator) simulation traffic generator class instance
% :Results: (MetricRecorder) simulation results class instance

% Clean workspace
clearvars;
clc;
close all;

% Create a simulation config object
monsterLog('(SETUP) generating simulation configuration', 'NFO');
Config = MonsterConfig();



% Configure logs
setpref('monsterLog', 'logToFile', Config.Logs.logToFile);
setpref('monsterLog', 'logFile', Config.Logs.defaultLogName);

% Create network layout
monsterLog('(SETUP) setting up network layout', 'NFO');
Config.setupNetworkLayout()

% Setup eNodeBs
monsterLog('(SETUP) setting up simulation eNodeBs', 'NFO');
Stations = setupStations(Config);

% Setup UEs
monsterLog('(SETUP) setting up simulation UEs', 'NFO');
Users = setupUsers(Config);

% Setup channel
monsterLog('(SETUP) setting up simulation channel', 'NFO');
Channel = setupChannel(Stations, Users, Config);

% Setup traffic
monsterLog('(SETUP) setting up simulation traffic', 'NFO');
[Traffic, Users] = setupTraffic(Users, Config);

% Setup results
monsterLog('(SETUP) setting up simulation metrics recorder', 'NFO');
Results = setupResults(Config);
	
end