function compileResults(Param, utilLoList, utilHiList, Stations, Users)

%   COMPILE RESULTS is a simple utility to compile all results files
%
%   Function fingerprint
%   Param						->  general simulation parameters
%   utilLoList			->  list of low utility values used
%   utilHiList			->  list of high utility values used
%		Stations				->	eNodeBs to save with the results
%		Users						->	UEs to save with the results

% Load result files using their naming patterns
filePattern = fullfile('results', 'utilLo_*.mat');
resultFiles = dir(filePattern);

% allocate struct to hold compiled data
enbOut(1:length(utilLoList),1:length(utilHiList), 1:Param.schRounds, ...
	1:Param.numMacro + Param.numMicro) = struct('power', 0, 'util', 0);

ueOut(1:length(utilLoList),1:length(utilHiList), 1:Param.schRounds, ...
	1:Param.numUsers) = struct(...
	'blocks', [],...
	'cqi', 0,...
	'preEvm', 0,...
	'postEvm', 0,....
	'bits', [],...
	'sinr', 0,...
	'snr',0,...
	'rxPosition', [],...
	'txPosition', []);

for iFile = 1:length(resultFiles)
	fileName = fullfile('results', resultFiles(iFile).name);
	fileData = load(fileName);
	
	% get the indexes for storing based on the utilisation values
	iUtilLo = find(utilLoList == fileData.infoResults.utilLo);
	iUtilHi = find(utilHiList == fileData.infoResults.utilHi);
	
	enbOut(iUtilLo, iUtilHi,:,:) = fileData.enbResults;
	ueOut(iUtilLo, iUtilHi,:,:) = fileData.ueResults;
end

% once done, save to mat file the compiled output
save(strcat('results/compiled.mat'), 'enbOut', 'ueOut', 'Stations', 'Users');
end
