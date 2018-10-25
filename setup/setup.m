function [Config, Stations, Users, Traffic, Channel, ChannelEstimator] = setup()
% setup - performs all the task related to setting up a simulation 
%
% Syntax: [Config, Stations, Users, Traffic, Channel, ChannelEstimator] = setup()
% setup is called from the main file and returns the following
% 

% Clean workspace
clearvars;
clc;
close all;

% Load parameters structure
if exist('SimulationParameters', 'file') == 2
	load('SimulationParameters.mat');
else
	SimulationParameters;

% Install directories structure
install(Param.reset);

% Create a simulation config object
Config = MonsterConfig(Param);

% Configure logs





	
end