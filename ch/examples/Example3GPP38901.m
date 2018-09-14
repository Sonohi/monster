clear all
close all
initParam
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
Param.numUsers = 1;

Param.channel.enableInterference = false;
Param.channel.enableFading = false;
Param.channel.enableShadowing = true;
Param.channel.LOSMethod = '3GPP38901-probability';
Param.channel.modeDL = '3GPP38901';
Param.area = [-1000, -1000, 1000, 1000];
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';


if Param.draw
	Param = createLayoutPlot(Param);
	Param = createPHYplot(Param);
end

% Create Stations and Users
[Station, Param] = createBaseStations(Param);
User = createUsers(Param);

% Create Channel scenario
ChannelUMa = ChBulk_v2(Station, User, Param);


Param.channel.region.macroScenario = 'RMa';
ChannelRMa = ChBulk_v2(Station, User, Param);

whwat :j
Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

% A full LTE frame is stored in Tx.Frame which can be used to debug and
% test.
Station.Tx.Waveform = Station.Tx.Frame;
Station.Tx.WaveformInfo = Station.Tx.FrameInfo;
Station.Tx.ReGrid = Station.Tx.FrameGrid;

% Traverse channel
[~, User] = ChannelUMa.traverse(Station,User,'downlink');

% Get offset
User.Rx.Offset = lteDLFrameOffset(Station, User.Rx.Waveform);

% Apply offset
User.Rx.Waveform = User.Rx.Waveform(1+User.Rx.Offset:end);

% UE reference measurements
User.Rx = User.Rx.referenceMeasurements(Station);


%% Produce heatmap for channel conditions with spatial correlation
% This includes:
% * LOS stateStation
% * Shadowing
% * Pathloss
setpref('sonohiLog','logLevel', 4);
Station.Position(1:2) = [0, 0];
% Set up coordinates of UE
sweepRes = 20; %1m

% Get area size
lengthXY = [Param.area(1):sweepRes:Param.area(3); Param.area(2):sweepRes:Param.area(4)];
N = length(lengthXY(1,:));
resultsUMa = cell(N,N);
resultsRMa = cell(N,N);
counter = 0;
for Xpos = 1:length(lengthXY(1,:))
    
    for Ypos = 1:length(lengthXY(2,:))
        fprintf('Sim %i/%i\n',counter,N^2);
        ue = User;
        ue.Position(1:2) = [lengthXY(1,Xpos), lengthXY(2,Ypos)];
        % Traverse channel
        try
            [~, ueUMa] = ChannelUMa.traverse(Station,ue,'downlink');
            [~, ueRMa] = ChannelRMa.traverse(Station,ue,'downlink');
        catch ME
            
        end
        
        resultsUMa{Xpos,Ypos} = ueUMa.Rx.ChannelConditions;
        resultsRMa{Xpos,Ypos} = ueRMa.Rx.ChannelConditions;
        counter = counter +1;
        
    end
end

%% Create visualization vectors/matrices

UMaResultsLOS = nan(N,N);
UMaResultsPL = nan(N,N);
UMaResultsLSP = nan(N,N);
UMaResultsLOSprop = nan(N,N);

RMaResultsLOS = nan(N,N);
RMaResultsPL = nan(N,N);
RMaResultsLSP = nan(N,N);
RMaResultsLOSprop = nan(N,N);
for Xpos = 1:length(lengthXY(1,:))
    
    for Ypos = 1:length(lengthXY(2,:))
        
        UMaResultsLOS(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LOS;
        UMaResultsPL(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.pathloss;
        UMaResultsLSP(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LSP;
        UMaResultsLOSprop(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LOSprop;
        
        RMaResultsLOS(Xpos,Ypos) = resultsRMa{Xpos,Ypos}.LOS;
        RMaResultsPL(Xpos,Ypos) = resultsRMa{Xpos,Ypos}.pathloss;
        RMaResultsLSP(Xpos,Ypos) = resultsRMa{Xpos,Ypos}.LSP;
        RMaResultsLOSprop(Xpos,Ypos) = resultsRMa{Xpos,Ypos}.LOSprop;
        
    end
end

%% Plotting

close all

figure
contourf(lengthXY(1,:), lengthXY(2,:), UMaResultsPL)
caxis([70 150])
c = colorbar;
c.Label.String = 'loss [dB]';
c.Label.FontSize = 12;
colormap jet
title('UMa \mu pathloss, 1.84 GHz')
xlabel('X [m]')
ylabel('Y [m]')



figure
contourf(lengthXY(1,:), lengthXY(2,:), RMaResultsPL)
caxis([70 150])
c = colorbar;
c.Label.String = 'loss [dB]';
c.Label.FontSize = 12;
colormap jet
title('RMa \mu pathloss, 1.84 GHz')
xlabel('X [m]')
ylabel('Y [m]')




figure
contourf(lengthXY(1,:), lengthXY(2,:), UMaResultsLOS,1)
title('LOS state for UMa')

figure
contourf(lengthXY(1,:), lengthXY(2,:), RMaResultsLOS,1)
title('LOS state for RMa')
colormap summer

figure
contourf(lengthXY(1,:), lengthXY(2,:), UMaResultsLSP)
colorbar
colormap jet

figure
contourf(lengthXY(1,:), lengthXY(2,:), UMaResultsLOSprop)
colorbar
colormap jet