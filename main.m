%	MAIN
%
%	numFrames = number of LTE frames for which to run each sim
sonohi;

clear;
clc;
close all;

param.numFrames = 10;

%create base stations
param.numSubFramesMacro = 50;
param.numSubFramesMicro = 25;
param.macroNum = 1;
param.microNum = 5;
param.seed = 122;
param.buildings = load('mobility/buildings.txt');

% Channel configuration
param.Channel.mode = 'fading'; % ['mobility','fading'];


%Guard for initial setup: exit of there's more than 1 macro BS
if (param.macroNum ~= 1)
	return;
end

stations = createBaseStations(param);

%Create channels
channels = createChannels(stations,param); %
%Create channel estimator
cec = createChEstimator();
