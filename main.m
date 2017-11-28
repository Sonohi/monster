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
setpref('sonohiLog','logLevel',4)

% Load simulation parameters from config file
try
	Param = loadConfig('simulation.config');
catch ME
	disp('Initialising project');
	sonohi(1);
	Param = loadConfig('simulation.config');
end

validateParam(Param);

Param.buildings = load(Param.buildings);
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
	max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.buildingHeight],[1 length(Param.buildings(:,1))]);
Param.channel.modeDL = Param.channelModeDL;
Param.channel.modeUL = Param.channelModeUL;
Param = rmfield(Param, 'channelModeDL');
Param = rmfield(Param, 'channelModeUL');
Param.channel.region = Param.channelRegion;
Param = rmfield(Param, 'channelRegion');
Param.harq.rtxMax = Param.harqRtx;
Param = rmfield(Param, 'harqRtx');
Param.harq.rv = Param.rvSeq;
Param = rmfield(Param, 'rvSeq');
Param.harq.proc = Param.harqProc;
Param = rmfield(Param, 'harqProc');
Param.harq.tout = Param.harq.proc/2 -1;
Param.arq.maxBufferSize = Param.arqBufferSize;
Param = rmfield(Param, 'arqBufferSize');
Param.arq.bufferFlushTimer = Param.arqBufferFlush;
Param = rmfield(Param, 'arqBufferFlush');
Param.arq.rtxMax = Param.arqRtx;
Param = rmfield(Param, 'arqRtx');
Param.bsNoiseFigure = 3;
Param.BaseSeed = 42;
Param.PRACHInterval = 10; %Given as the number of subframes between each PRACH.

sonohi(Param.reset);

% Disable warnings about casting classes to struct
w = warning('off', 'all');

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
utilLo = 1:Param.utilLoThr;
utilHi = Param.utilHiThr:100;

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

% compile all results files
compileResults(Param, utilLo, utilHi, Stations, Users);
