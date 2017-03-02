%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MAIN 																										                   %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;
close all;

% Simulation parameters
param.reset = 1;
param.numFrames = 10;
param.numSubFramesMacro = 50;
param.numSubFramesMicro = 25;
param.macroNum = 1;
param.microNum = 5;
param.seed = 122;
param.buildings = load('mobility/buildings.txt');
param.velocity = 3; %in km/h
param.numUsers = 15;
param.utilLoThr = 1;
param.utilHiThr = 51;

sonohi(param.reset);

% Channel configuration
param.Channel.mode = 'fading'; % ['mobility','fading'];

% Guard for initial setup: exit of there's more than 1 macro BS
if (param.macroNum ~= 1)
	return;
end

stations = createBaseStations(param);
users = createUsers(param);

% Create channels
channels = createChannels(stations,param); %
%Create channel estimator
cec = createChEstimator();

% Get traffic source data and check if we have already the MAT file with the traffic data
if (exist('traffic/trafficSource.mat', 'file') ~= 2 || param.reset)
	trSource = getTrafficData('traffic/bunnyDump.csv');
else
	trSource = load('traffic/trafficSource.mat', 'data');
end

% Utilisation ranges
if (param.utilLoThr > 0 && param.utilLoThr <= 100 && param.utilHiThr > 0 && ...
	 	param.utilHiThr <= 100)
	utilLo = 1:param.utilLoThr;
	utilHi = param.utilHiThr:100;
else
	return;
end


%Main loop
for (utilLoIx = 1: length(utilLo))
	for (utilHiIx = 1:length(utilHi))


	end
end
