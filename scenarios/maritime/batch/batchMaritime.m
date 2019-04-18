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

batchSeeds = [126 60 89 200 45];
parfor iSeed = 1:2
	for toggleSweep = 0:1
		try
			batchSimulation(batchSeeds(iSeed), toggleSweep);
		catch ME
			monsterLog(sprintf('(BATCH MAIN) Error in batch for simulation index %i', i),'WRN');
			monsterLog(ME.stack);
		end	
	end
end

%{
 parfor i = 1:5
	try
		batchSimulation(batchSeeds(i));
	catch ME
		monsterLog(sprintf('(BATCH MAIN) Error in batch for simulation index %i', i),'WRN');
		monsterLog(ME.stack);
	end			
end 
%}
