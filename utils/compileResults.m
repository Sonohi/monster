function out = compileResults(Param, utilLoList, utilHiList)

	%   COMPILE RESULTS is a simple utility to compile all results files
	%
	%   Function fingerprint
	%   Param						->  general simulation parameters
	%   utilLoList			->  list of low utility values used
	%   utilHiList			->  list of high utility values used

	% Load result files using their naming patterns
	filePattern = fullfile('results', 'utilLo_*.mat');
	resultFiles = dir(filePattern);

	% allocate struct to hold compiled data
	out = struct('cqi', zeros(length(utilLoList), length(utilHiList), Param.numUsers, Param.schRounds), ...
		'sinr', zeros(length(utilLoList), length(utilHiList), Param.numUsers, Param.schRounds));

	for iFile = 1:length(resultFiles)
		fileName = fullfile('results', resultFiles(iFile).name);
		fileData = load(fileName);

		% get the indexes for storing based on the utilisation values
		iUtilLo = find(utilLoList == fileData.Results.info.utilLo);
		iUtilHi = find(utilHiList == fileData.Results.info.utilHi);

		out.cqi(iUtilLo, iUtilHi, :, :) = fileData.Results.cqi;
		out.sinr(iUtilLo, iUtilHi, :, :) = fileData.Results.sinr;

	end

	% once done, save to mat file the compiled output
	save(strcat('results/compiled.mat'), 'out');
end
