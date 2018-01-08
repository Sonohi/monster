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
initParam; 

% Set Log level
setpref('sonohiLog','logLevel',4)

validateParam(Param);

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
switch Param.trafficModel
	case 'videoStreaming'
		if (exist('traffic/videoStreaming.mat', 'file') ~= 2 || Param.reset)
			trSource = loadVideoStreamingTraffic('traffic/videoStreaming.csv', true);
		else
			load('traffic/videoStreaming.mat', 'trSource');
		end
	case 'fullBuffer'
		if (exist('traffic/fullBuffer.mat', 'file') ~= 2 || Param.reset)
			trSource = loadFullBufferTraffic('traffic/fullBuffer.csv');
		else
			load('traffic/fullBuffer.mat', 'trSource');
		end
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
