% batchMain
%
% Main batch manager to parallelise the execution of the various instances
%

% Assert whether a folder for the daily results exists, otherwise create it
folderPath = strcat('results/maritime/', datestr(datetime, 'yyyy.mm.dd'));
if ~exist(folderPath, 'dir')
	mkdir(folderPath);
	mkdir(strcat(folderPath, '/no_sweep'));
	mkdir(strcat(folderPath, '/sweep'));
end

batchSeeds = [45 60 75 112 126 135 200];
parfor iSeed = 1:length(batchSeeds)
	for toggleSweep = 0:1
		try
			batchSimulation(batchSeeds(iSeed), toggleSweep);
		catch ME
			disp(sprintf('(BATCH MAIN) Error in batch for simulation index %i'));
		end	
	end
end
