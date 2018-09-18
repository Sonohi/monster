% This script showcase the mean pathloss using the different channel models
% implemented. 

clear all
close all
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
Param.numUsers = 1;
Param.draw = 0;


if Param.draw
	Param = createLayoutPlot(Param);
	Param = createPHYplot(Param);
end

% Create Stations and Users
[Station, Param] = createBaseStations(Param);
User = createUsers(Param);

% Create Channel scenarios
Param.channel.enableInterference = false;
Param.channel.enableFading = false;
Param.channel.enableShadowing = true;
Param.channel.LOSMethod = '3GPP38901-probability';
Param.channel.modeDL = '3GPP38901';
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';
Param.mobilityScenario = 'pedestrian';
ChannelUMa = ChBulk_v2(Station, User, Param);

Param.channel.region.macroScenario = 'UMi';
ChannelUMi = ChBulk_v2(Station, User, Param);

Param.channel.region.macroScenario = 'RMa';
ChannelRMa = ChBulk_v2(Station, User, Param);

Param.channel.LOSMethod = 'fresnel';
Param.channel.region = 'Dense Urban';
Param.channel.modeDL = 'ITU1546';
Param.channel.enableShadowing = false;
ChITUDenseUrban = ChBulk_v2(Station, User, Param);

Param.channel.modeDL = 'ITU1546';
Param.channel.region = 'Urban';
ChITUUrban = ChBulk_v2(Station, User, Param);

%Param.channel.modeDL = 'winner';
%Param.channel.region = struct();
%Param.channel.region.macroScenario = '11';
%ChWINNER = ChBulk_v2(Station, User, Param);

Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

% A full LTE frame is stored in Tx.Frame which can be used to debug and
% test.
Station.Tx.Waveform = Station.Tx.Frame;
Station.Tx.WaveformInfo =Station.Tx.FrameInfo;
Station.Tx.ReGrid = Station.Tx.FrameGrid;

distanceXY = 10:10:300;
distanceTotal = sqrt(distanceXY.^2+distanceXY.^2);
N = length(distanceXY);
resultsUMa = NaN(N,2);
resultsUMi = NaN(N,2);
resultsRMa = NaN(N,2);
resultsITUDenseUrban = NaN(N,2);
resultsITUUrban = NaN(N,2);
resultsWINNER = NaN(N,2);
Station.Position(1:2) = [0, 0]; 
for distanceIdx = 1:N
	fprintf('Distance %i/%i\n',distanceXY(distanceIdx),distanceXY(end));
	bs = Station;
	ue = User;
	
	xDiff = bs.Position(1)+distanceXY(distanceIdx); %in M
	yDiff = bs.Position(2)+distanceXY(distanceIdx);
  ue.Position = [xDiff, yDiff, 1.5];
% 	% Traverse channel
	[~, ueUMa] = ChannelUMa.traverse(bs,ue,'downlink');
	[~, ueUMi] = ChannelUMi.traverse(bs,ue,'downlink');
	[~, ueRMa] = ChannelRMa.traverse(bs,ue,'downlink');
	[~, ueITUDU] = ChITUDenseUrban.traverse(bs, ue, 'downlink');
	[~, ueITUU] = ChITUUrban.traverse(bs, ue, 'downlink');
	%[~, ueWINNER] = ChWINNER.traverse(bs, ue, 'downlink');

	% Get offset
	ueUMa.Rx.Offset = lteDLFrameOffset(bs, ueUMa.Rx.Waveform);
	ueUMi.Rx.Offset = lteDLFrameOffset(bs, ueUMi.Rx.Waveform);
	ueRMa.Rx.Offset = lteDLFrameOffset(bs, ueRMa.Rx.Waveform);
	ueITUDU.Rx.Offset = lteDLFrameOffset(bs, ueITUDU.Rx.Waveform);
	ueITUU.Rx.Offset = lteDLFrameOffset(bs, ueITUU.Rx.Waveform);
	%ueWINNER.Rx.Offset = lteDLFrameOffset(bs, ueWINNER.Rx.Waveform);
	
	
	
	% Apply offset
	ueUMa.Rx.Waveform = ueUMa.Rx.Waveform(1+ueUMa.Rx.Offset:end);
	ueUMi.Rx.Waveform = ueUMi.Rx.Waveform(1+ueUMi.Rx.Offset:end);
	ueRMa.Rx.Waveform = ueRMa.Rx.Waveform(1+ueRMa.Rx.Offset:end);
	ueITUDU.Rx.Waveform = ueITUDU.Rx.Waveform(1+ueITUDU.Rx.Offset:end);
	ueITUU.Rx = ueITUU.Rx.applyOffset();
	%ueWINNER.Rx = ueWINNER.Rx.applyOffset();

	% UE reference measurements
	ueUMa.Rx = ueUMa.Rx.referenceMeasurements(bs);
	resultsUMa(distanceIdx,1) = ueUMa.Rx.SNRdB;
	resultsUMa(distanceIdx,2) = ueUMa.Rx.RxPwdBm;
	
	ueUMi.Rx = ueUMi.Rx.referenceMeasurements(bs);
	resultsUMi(distanceIdx,1) = ueUMi.Rx.SNRdB;
	resultsUMi(distanceIdx,2) = ueUMi.Rx.RxPwdBm;
	
	ueRMa.Rx = ueRMa.Rx.referenceMeasurements(bs);
	resultsRMa(distanceIdx,1) = ueRMa.Rx.SNRdB;
	resultsRMa(distanceIdx,2) = ueRMa.Rx.RxPwdBm;
	
	ueITUDU.Rx = ueITUDU.Rx.referenceMeasurements(bs);
	resultsITUDenseUrban(distanceIdx,1) = ueITUDU.Rx.SNRdB;
	resultsITUDenseUrban(distanceIdx,2) = ueITUDU.Rx.RxPwdBm;
		
	ueITUU.Rx = ueITUU.Rx.referenceMeasurements(bs);
	resultsITUUrban(distanceIdx,1) = ueITUU.Rx.SNRdB;
	resultsITUUrban(distanceIdx,2) = ueITUU.Rx.RxPwdBm;
	
			
	%ueWINNER.Rx = ueWINNER.Rx.referenceMeasurements(bs);
	%resultsWINNER(distanceIdx,1) = ueWINNER.Rx.SNRdB;
	%resultsWINNER(distanceIdx,2) = ueWINNER.Rx.RxPwdBm;
end
figure; 
plot(distanceTotal, resultsUMa(:,2));
hold on
plot(distanceTotal, resultsUMi(:,2));
plot(distanceTotal, resultsRMa(:,2));
plot(distanceTotal, resultsITUDenseUrban(:,2));
plot(distanceTotal, resultsITUUrban(:,2));
%plot(distanceTotal, resultsWINNER(:,2));
legend('UMa','UMi','RMa','ITU Dense Urban', 'ITU Urban', 'WINNER Urban');