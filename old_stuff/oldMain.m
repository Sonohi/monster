%   MAIN
%
%   Simulation Parameters
%		reset 						-> 	resets the paths and refreshes them
%		schRounds 				->	overall length of the simulation
%		numSubFramesMacro ->	bandwidth of macro cell
%													(100 subframes = 20 MHz bandwidth)
%		numSubFramesMicro ->	bandwidth of micro cell
%		numMacro 					->	number of macro cells
%		numMicro					-> 	number of micro cells
%		seed							-> 	seed for channel
%		buildings					->	file path for coordinates of Manhattan grid
%		velocity					->	velocity of Users
%		numUsers					-> 	number of Users
%		utilLoThr					->	lower threshold of utilisation
%		utilHiThr					->	upper threshold of utilisation
%		Channel.mode			->	channel model to be used

clearvars;
clc;
close all;

% Load parameters
load('SimulationParameters.mat');

% Set log preferences
dateStr = datestr(datetime, 'yyyy-mm-dd_HH.MM.SS');
logName = strcat('logs/', dateStr, '-utilLoThr_',num2str(Param.utilLoThr), '-numUsers_',num2str(Param.numUsers),'.txt');
setpref('sonohiLog', 'logToFile', Param.logToFile);
setpref('sonohiLog', 'logFile', logName);

sonohi(Param.reset);

validateParam(Param);


% Disable warnings about casting classes to struct
w = warning('off', 'all');

if Param.draw
	Param = createLayoutPlot(Param);
	Param = createPHYplot(Param);
end

% Create Stations, Users and Traffic generators
[Stations, Param] = createBaseStations(Param);

Users = createUsers(Param);
[Users, TrafficGenerators] = trafficGeneratorBulk(Users, Param);


% Create Channel scenario
Channel = ChBulk_v2(Stations, Users, Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();

% Utilisation ranges
utilLo = 1:Param.utilLoThr;
utilHi = Param.utilHiThr:100;

% Create struct to pass data to the simulation function
simData = struct(...
	'TrafficGenerators', TrafficGenerators,...
	'Stations', Stations,...
	'Users', Users,...
	'Channel', Channel,...
	'ChannelEstimator', ChannelEstimator);

% if set, clean the results folder
if Param.rmResults
	removeResults();
end

% create powerState mapping
powerState = [
	"active", ...
	"overload", ...
	"underload", ...
	"shutdown", ...
	"inactive", ...
	"boot"];

% Main loop

for iUtilLo = 1: length(utilLo)
	for iUtilHi = 1:length(utilHi)
		simulate(Param, simData, utilLo(iUtilLo), utilHi(iUtilHi));
	end
end
