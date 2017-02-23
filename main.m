%	MAIN
%
%	numFrames = number of LTE frames for which to run each sim
sonohi;

clear;
clc;
close all;

numFrames = 10;

%create base stations
numSubFramesMacro = 50;
numSubFramesMicro = 25;
macroNum = 1;
microNum = 5;
seed = 122;

%Guard for initial setup: exit of there's more than 1 macro BS
if (macroNum ~= 1)
	return;
end

%stations = createBaseStations(macroNum, numSubFramesMacro, microNum, numSubFramesMicro);

%Create channels
%channels = createChannels(stations, seed,  'fading'); % ['fading', 'mobility'] % TODO: move this to a channel config struct
%Create channel estimator
%cec = createChEstimator();
