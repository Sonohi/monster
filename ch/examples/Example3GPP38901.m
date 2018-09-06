clear all
close all
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


Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

% A full LTE frame is stored in Tx.Frame which can be used to debug and
% test.
Station.Tx.Waveform = Station.Tx.Frame;
Station.Tx.WaveformInfo =Station.Tx.FrameInfo;
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
sweepRes = 10; %1m

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
        % Get offset
        %ue.Rx.Offset = lteDLFrameOffset(Station, ue.Rx.Waveform);

        % Apply offset
        %ue.Rx.Waveform = ue.Rx.Waveform(1+ue.Rx.Offset:end);
        % UE reference measurements
        %ue.Rx = ue.Rx.referenceMeasurements(Station);
        
        resultsUMa{Xpos,Ypos} = ueUMa.Rx.ChannelConditions;
        resultsRMa{Xpos,Ypos} = ueRMa.Rx.ChannelConditions;
        counter = counter +1;
        
    end
end

%%

resultsLOS = nan(N,N);
resultsPL = nan(N,N);
resultsLSP = nan(N,N);
resultsLOSprop = nan(N,N);
for Xpos = 1:length(lengthXY(1,:))
    
    for Ypos = 1:length(lengthXY(2,:))
        
        resultsLOS(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LOS;
        resultsPL(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.pathloss;
        resultsLSP(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LSP;
        resultsLOSprop(Xpos,Ypos) = resultsUMa{Xpos,Ypos}.LOSprop;
        
    end
end

close all

figure
contourf(lengthXY(1,:), lengthXY(2,:), resultsPL)
colorbar
colormap jet

figure
contourf(lengthXY(1,:), lengthXY(2,:), resultsLOS,1)
colormap summer

figure
contourf(lengthXY(1,:), lengthXY(2,:), resultsLSP)
colorbar
colormap jet

figure
contourf(lengthXY(1,:), lengthXY(2,:), resultsLOSprop)
colorbar
colormap jet