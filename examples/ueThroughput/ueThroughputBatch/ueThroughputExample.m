% batchMain
%
% Main batch manager to parallelise the execution of the various instances
%

%Number different scenarios to be run
numScenarios = 5;

%Create fodler to save results in
folderPath = strcat('examples/ueThroughput/results/', datestr(datetime, 'yyyy.mm.dd'));
createFolders(folderPath, numScenarios);

%Set up for simulation
simulationChoice = 1:numScenarios;

parfor iSimulation = simulationChoice %Change this "for" to "parfor" to enable parrelization for speed optimizing
  % If one or more simulation fails, the rest will still run
  try
    %Run the simulation
    ueBatchSimulation(iSimulation, folderPath);
  catch ME
    fprintf('(BATCH MAIN) Error in batch for simulation index %i\n', iSimulation);
    ME
  end
end


% This function creates folders for the result of the simulation
function createFolders(folderPath, numScenarios)
  % Assert whether a folder for the daily results exists, otherwise create it
  
  if ~exist(folderPath, 'dir')
    mkdir(folderPath);
    if numScenarios >= 1
      mkdir(strcat(folderPath, '/baseline'));
    end
    if numScenarios >= 2
      mkdir(strcat(folderPath, '/bandwidth'));
    end
    if numScenarios >= 3
      mkdir(strcat(folderPath, '/withMicro'));
    end
    if numScenarios >= 4
      mkdir(strcat(folderPath, '/withoutBackhaul'));
    end
    if numScenarios >= 5
      mkdir(strcat(folderPath, '/withBackhaul'));
    end
    if numScenarios > 5
      disp('Unknown number of scenarios, only up to 5 supported');
    end
  end
end