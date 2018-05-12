%% replaySimulation
clear all
close all


%mode = 'perUser'; %perUser

% Just run me. or select user/station by setting parameter
%sUser = 2;
%sStation = 1;

%% Initialization
fprintf('Loading results...')
load('results/seed_42-utilLo_1-utilHi_100-numUsers_15.mat')

Param = createLayoutPlot(SimulationMetrics.Param);

% Create Stations, Users and Traffic generators
[Stations, SimulationMetrics.Param] = createBaseStations(Param);
ENBsummaryplt = ENBsummaryPlot(Stations);
    
Users = createUsers(Param);

UEsummaryplt = UESummaryPlot(Users);



for iRound = 1:Param.schRounds
    simTime = iRound * 0.001;
%     for stationIdx = 1:length(Stations)
%         station = Stations(stationIdx);
%         ENBsummaryplt.addData(station.NCellID, 'PowerState', simTime, SimulationMetrics.powerState(iRound,stationIdx));
%         ENBsummaryplt.addData(station.NCellID, 'PowerConsumed', simTime, SimulationMetrics.powerConsumed(iRound,stationIdx));
%         ENBsummaryplt.addData(station.NCellID, 'HARQ', simTime, SimulationMetrics.harqRtx(iRound,stationIdx));
%         ENBsummaryplt.addData(station.NCellID, 'Utilization', simTime, SimulationMetrics.util(iRound,stationIdx));
%         
%     end
%     
    for userIdx = 1:length(Users)
       user = Users(userIdx);
       UEsummaryplt.addData(user.NCellID, 'BER', simTime, SimulationMetrics.ber(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'preEVM', simTime, SimulationMetrics.preEvm(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'postEVM', simTime, SimulationMetrics.postEvm(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'CQI', simTime, SimulationMetrics.cqi(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'SNR', simTime, SimulationMetrics.snrdB(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'SINR', simTime, SimulationMetrics.sinrdB(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'ReceivedPower', simTime, SimulationMetrics.receivedPowerdBm(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'RSRP', simTime, SimulationMetrics.rsrpdBm(iRound, userIdx));
       UEsummaryplt.addData(user.NCellID, 'Throughput', simTime, SimulationMetrics.throughput(iRound, userIdx));
    end
    drawnow
end
% if isnan(sUser) && isnan(sStation)
% fprintf('View parameters not set.\n')
% if strcmp(mode,'perStation')
%   disp('Which station would you like to display?')
%   poss = sprintf('%.0f,',[Stations.NCellID]);
%   fprintf('Possibilities: %s',poss(1:end-1))
%   sStation = input('\n');
% elseif strcmp(mode,'perUser')
%   disp('Which user would you like to display?')
%   poss = sprintf('%.0f,',[Users.UeId]);
%   fprintf('Possibilities: %s',poss(1:end-1))
%   sUser = input('\n');
% end
% end
%
%
% %% Standard display values (axis ranges)
%
% Param.EVM = [0 100];
% Param.CQI = [0 15];
% Param.bitrate = [0 10e11];
% Param.SNR = [-80 120];
% Param.SINR = [-80 120];
% Param.distance = [0 300];
%
% Param.Area = [0 300 0 300];
% Param.NoStations = length(Stations);
%
% temp = [Stations.Position];
% Param.StationPos = reshape(temp,3,Param.NoStations);
%
%
%
% if strcmp(mode,'perStation')
%
%   station = Stations(sStation);
%
%   displayStation(enbOut,Stations,sStation,Param, ueOut, Users)
%
%
% elseif strcmp(mode, 'perUser')
%   while true
%     data = extractUserMetrics(ueOut,Users,Param);
%     displayUser(sUser,data,Param)
%     fprintf('Replay? (y/n) ')
%     rep = input('\n','s');
%     if ~strcmp(rep,'y')
%       rep = input('Select a different user? (n for exit) \n','s');
%       if strcmp(rep,'n')
%         break
%       else
%         sUser = str2num(rep);
%       end
%     end
%   end
%
% end