%
% Utility to process the results of a batch simulation
%

basePath = 'results/maritime/2019.05.21';
noSweepPath = strcat(basePath, '/no_sweep');
sweepPath = strcat(basePath, '/sweep');

% Get a list of the filenames in each folder
folderInfo = dir(strcat(noSweepPath, '/*.mat'));
fileNames = cellfun(@(x) fullfile(strcat(noSweepPath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
if ~isempty(fileNames)
	% Construct a structure to store all the values and get info from the
	% first file
	load(fileNames{1});
	Config = storedResults.config;
	clear storedResults;
	aggNoSweep = struct(...
		'sinr', zeros(length(fileNames), Config.Runtime.simulationRounds),...
		'power', zeros(length(fileNames), Config.Runtime.simulationRounds));
	for iFile = 1:length(fileNames)
		load(fileNames{iFile});
		aggNoSweep.sinr(iFile, :) = storedResults.sinr;
		aggNoSweep.power(iFile, :) = storedResults.power;
		clear storedResults;
	end
end

folderInfo = dir(strcat(sweepPath, '/*.mat'));
fileNames = cellfun(@(x) fullfile(strcat(sweepPath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
if ~isempty(fileNames)
	% Construct a structure to store all the values and get info from the
	% first file
	load(fileNames{1});
	Config = storedResults.config;
	clear storedResults;
	aggSweep = struct(...
		'sinr', zeros(length(fileNames), Config.Runtime.simulationRounds),...
		'power', zeros(length(fileNames), Config.Runtime.simulationRounds));
	for iFile = 1:length(fileNames)
		load(fileNames{iFile});
		aggSweep.sinr(iFile, :) = storedResults.sinr;
		aggSweep.power(iFile, :) = storedResults.power;
		clear storedResults;
	end
end

% Combine the results taking the mean values across experiments
avSinrNoSweep = mean(aggNoSweep.sinr, 1);
avPowerNoSweep = mean(aggNoSweep.power, 1);
avSinrSweep = mean(aggSweep.sinr, 1);
avPowerSweep = mean(aggSweep.power, 1);
