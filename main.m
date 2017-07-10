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

%log
setpref('sonohiLog','logLevel',5)

% Load simulation parameters from config file
if ~exist('utils','dir')
	sonohi(1);
end
Param = loadConfig('simulation.config');
Param.buildings = load(Param.buildings);
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
	max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.buildingHeight],[1 length(Param.buildings(:,1))]);
Param.channel.mode = Param.channelMode;
Param.channel.region = Param.channelRegion;

sonohi(Param.reset);

% Disable warnings about casting classes to struct
w = warning('off', 'all');

% Channel configuration
Param.channel.mode = 'eHATA';
Param.channel.region = 'DenseUrban';

% Guard for initial setup: exit of there's more than 1 macro BS
if Param.numMacro ~= 1
	return;
end

% Create Stations and Users
[Stations, Param.AreaPlot] = createBaseStations(Param);
Users = createUsers(Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();

% Get traffic source data and check if we have already the MAT file with the traffic data
if (exist('traffic/trafficSource.mat', 'file') ~= 2 || Param.reset)
	trSource = loadTrafficData('traffic/bunnyDump.csv', true);
else
	load('traffic/trafficSource.mat', 'trSource');
end

% Utilisation ranges
if (Param.utilLoThr > 0 && Param.utilLoThr <= 100 && Param.utilHiThr > 0 && ...
		Param.utilHiThr <= 100)
	utilLo = 1:Param.utilLoThr;
	utilHi = Param.utilHiThr:100;
else
	return;
end

% Create struct to pass data to the simulation function
simData = struct('trSource', trSource, 'Stations', Stations, 'Users', Users,...
	'Channel', Channel, 'ChannelEstimator', ChannelEstimator);

% if set, clean the results folder
if Param.rmResults
	removeResults();
end

% create status mapping
status = [
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

% compile all results files and do some plots
compileResults(Param, utilLo, utilHi);
if Param.draw
	plotResults(Param, Stations, Users);
end
