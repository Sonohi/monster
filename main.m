%	MAIN 
% 
%	numFrames			= number of LTE frames for which to run each sim
%	numSubFramesMacro	= number of subframes availbale for macro eNodeB
%	numSubFramesMicro	= number of subframes availbale for micro eNodeB
clear
clc
close all

numFrames = 10;
numSubFramesMacro = 50;
numSubFramesMicro = 25;
macroNum = 1;
microNum = 5;

stations = createBaseStations(macroNum, numSubFramesMacro, microNum, numSubFramesMicro);


	







