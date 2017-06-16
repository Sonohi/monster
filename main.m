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

% Simulation Parameters
Param.reset = 0;
Param.draw = 1; % Enable plots
Param.storeTxData = 0;
Param.schRounds = 5;
Param.numSubFramesMacro = 50;
Param.numSubFramesMicro = 25;
Param.numMacro = 1;
Param.numMicro = 5;
Param.MacroHeight = 35; %Given in meters
Param.MicroHeight = 30;
Param.UEHeight = 1.5;
Param.BuildingHeight = [10,30]; % Height interval
Param.seed = 122;
Param.buildings = load('mobility/buildings.txt');
Param.velocity = 3; % in km/h
Param.numUsers = 15;
Param.utilLoThr = 1;
Param.utilHiThr = 100;
Param.ulFreq = 1747.5;
Param.dlFreq = 1842.5;
Param.maxTbSize = 97896;
Param.maxCwdSize = 10^5;
Param.maxSymSize = 10^5;
Param.scheduling = 'roundRobin';
Param.prbSym = 160;
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
	max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.BuildingHeight],[1 length(Param.buildings(:,1))]);
Param.freq = 1900; %Given in MHz
Param.nboRadius = 100; % maximum radius in m to include micro eNodeBs in neighbours
Param.hystMax = 2; % number of scheduling rounds used for hysteresis in BS switching

sonohi(Param.reset);

% Disable warnings about casting classes to struct
w = warning('off', 'all');

% Channel configuration
Param.channel.mode = 'B2B';
Param.channel.region = 'DenseUrban';

% Guard for initial setup: exit of there's more than 1 macro BS
if (Param.numMacro ~= 1)
	return;
end

% Create Stations and Users
[Stations, Param.AreaPlot] = createBaseStations(Param);
Users = createUsers(Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);
%Stations = createChannels(Stations,Param);

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
	
% Main loop
for iUtilLo = 1: length(utilLo)
	for iUtilHi = 1:length(utilHi)
		simulate(Param, simData, utilLo(iUtilLo), utilHi(iUtilHi));
	end;
end;

% compile all results files and do some plots
compileResults(Param, utilLo, utilHi);
if Param.draw
	plotResults(Param, Stations, Users);
end
