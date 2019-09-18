% batchMain
%
% Main batch manager to parallelise the execution of the various instances
%

% Assert whether a folder for the daily results exists, otherwise create it
folderPath = strcat('examples/results/ueThroughput/', datestr(datetime, 'yyyy.mm.dd'));
if ~exist(folderPath, 'dir')
	mkdir(folderPath);
	mkdir(strcat(folderPath, '/baseline'));
	mkdir(strcat(folderPath, '/bandwidth'));
  mkdir(strcat(folderPath, '/fewUsers'));
  mkdir(strcat(folderPath, '/withMicro'));
end

simulationChoice = 1:4;

for iSimulation = simulationChoice
  try
    ueBatchSimulation(iSimulation, folderPath);
  catch ME
    fprintf('(BATCH MAIN) Error in batch for simulation index %i\n', iSimulation);
    ME
  end
end