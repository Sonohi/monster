%% replaySimulation
clear all
close all


%% Initialization
fprintf('Loading results...')
load('results/seed_42-utilLo_1-utilHi_100-numUsers_15.mat')

Param = createLayoutPlot(SimulationMetrics.Param);

% Create Stations, Users and Traffic generators
[Stations, SimulationMetrics.Param] = createBaseStations(Param);
ENBsummaryplt = ENBsummaryPlot(Stations);
    
Users = createUsers(Param);

UEsummaryplt = UESummaryPlot(Users);

for iRound = 0:Param.schRounds-1
	
    simTime = iRound * 0.001;
		ENBsummaryplt.ENBBulkPlot(Stations, SimulationMetrics, iRound);
    UEsummaryplt.UEBulkPlot(Users, SimulationMetrics, iRound);
    drawnow
end