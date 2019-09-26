% batchMain
%
% Main batch manager to parallelise the execution of the various instances
%

% Assert whether a folder for the daily results exists, otherwise create it
folderPath = strcat('examples/ueThroughput/results/', datestr(datetime, 'yyyy.mm.dd'));
if ~exist(folderPath, 'dir')
	mkdir(folderPath);
	mkdir(strcat(folderPath, '/baseline'));
	mkdir(strcat(folderPath, '/bandwidth'));
  mkdir(strcat(folderPath, '/withMicro'));
  mkdir(strcat(folderPath, '/withoutBackhaul'));
  mkdir(strcat(folderPath, '/withBackhaul'));
end

simulationChoice = 1:5;

parfor iSimulation = simulationChoice %Change this "for" to "parfor" to enable parrelization for speed optimizing
  try
    ueBatchSimulation(iSimulation, folderPath);
  catch ME
    fprintf('(BATCH MAIN) Error in batch for simulation index %i\n', iSimulation);
    ME
  end
end