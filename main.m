%	MAIN 
% 
%	numFrames = number of LTE frames for which to run each sim


addpath(genpath('setup'));
addpath(genpath('mobility'));

clear;
clc;
close all;

numFrames = 10;

%create base stations and place them in the grid
numSubFramesMacro = 50;
numSubFramesMicro = 25;
macroNum = 1;
microNum = 5;
stations = createBaseStations(macroNum, numSubFramesMacro, microNum, numSubFramesMicro);


	







