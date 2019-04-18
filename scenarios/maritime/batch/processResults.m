%
% Utility to process the results of a batch simulation
%

basePath = 'results/maritime/2019.04.18';
noSweepPath = strcat(basePath, '/no_sweep');
sweepPath = strcat(basePath, '/sweep');

% Get a list of the filenames in each folder
folderInfo = dir(strcat(noSweepPath, '/*.mat'));
fileNames = cellfun(@(x) fullfile(strcat(noSweepPath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
if ~isempty(fileNames)
	% Construct a structure to store all the values and get info from the
	% first file
	load(fileNames{1});
	Config = Simulation.Config;
	clear Simulation;
	aggNoSweep = struct(...
		'sinr', zeros(length(fileNames), Config.Runtime.totalRounds),...
		'power', zeros(length(fileNames), Config.Runtime.totalRounds));
	for iFile = 1:length(fileNames)
		load(fileNames{iFile});
		aggNoSweep.sinr(iFile, :) = Simulation.Results.sinrdB;
		aggNoSweep.power(iFile, :) = Simulation.Results.receivedPowerdBm;
		clear Simulation;
	end
end

folderInfo = dir(strcat(sweepPath, '/*.mat'));
fileNames = cellfun(@(x) fullfile(strcat(sweepPath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
if ~isempty(fileNames)
	% Construct a structure to store all the values and get info from the
	% first file
	load(fileNames{1});
	Config = Simulation.Config;
	clear Simulation;
	aggSweep = struct(...
		'sinr', zeros(length(fileNames), Config.Runtime.totalRounds),...
		'power', zeros(length(fileNames), Config.Runtime.totalRounds));
	for iFile = 1:length(fileNames)
		load(fileNames{iFile});
		aggSweep.sinr(iFile, :) = Simulation.Results.sinrdB;
		aggSweep.power(iFile, :) = Simulation.Results.receivedPowerdBm;
		clear Simulation;
	end
end

% Combine the results taking the mean values across experiments
avSinrNoSweep = mean(aggNoSweep.sinr, 1);
avPowerNoSweep = mean(aggNoSweep.power, 1);
avSinrSweep = mean(aggSweep.sinr, 1);
avPowerSweep = mean(aggSweep.power, 1);
