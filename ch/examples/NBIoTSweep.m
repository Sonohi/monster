clear all
close all
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
Param.numUsers = 1;

Param.area = [-1000, -1000, 1000, 1000];
Param.channel.enableInterference = 0;
Param.channel.enableFading = 0;
Param.channel.enableShadowing = 0;



if Param.draw
	Param = createLayoutPlot(Param);
	Param = createPHYplot(Param);
end

% Create Stations and Users
[Station, Param] = createBaseStations(Param);
User = createUsers(Param);

% Create Channel scenario
Param.channel.region = 'Suburban';
Param.channel.modeDL = 'ITU1546';
ChSuburban = ChBulk_v2(Station, User, Param);
Param.channel.region = 'Urban';
Param.channel.modeDL = 'ITU1546';
ChUrban = ChBulk_v2(Station, User, Param);


Param.channel.enableShadowing = true;
Param.channel.LOSMethod = '3GPP38901-probability';
Param.channel.modeDL = '3GPP38901';
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';
Param.mobilityScenario = 'pedestrian-indoor';
Ch3gppUMa = ChBulk_v2(Station, User, Param);

Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

% Create NB-IoT reference frame
rc = 'R.NB.5-1'; % Allowed values are 'R.NB.5','R.NB.5-1','R.NB.6','R.NB.6-1','R.NB.7'
ngen = NBIoTDownlinkWaveformGenerator(rc);
[waveform,regrid,ofdmInfo] = ngen.generateWaveform;
spectrumAnalyzer = dsp.SpectrumAnalyzer(ngen.Config.NBRefP);
spectrumAnalyzer.ShowLegend = true;
spectrumAnalyzer.SampleRate = ofdmInfo.SamplingRate;
if ngen.Config.NBRefP == 1
    spectrumAnalyzer.ChannelNames = {['Signal for RMC ' rc ' (Port 2000)']};
    spectrumAnalyzer(waveform);
else % NBRefP == 2
    spectrumAnalyzer.ChannelNames = {['Signal for RMC ' rc ' (Port 2000)'], ...
        ['Signal for RMC ' rc ' (Port 2001)']};
    spectrumAnalyzer(waveform(:,1),waveform(:,2));
end

Station.Tx.Waveform = waveform(:,2);
Station.Tx.WaveformInfo = ofdmInfo;
Station.Tx.ReGrid = regrid;


Station900 = Station;
Station900.DlFreq = 900;

Station1800 = Station;
Station1800.DlFreq = 1800;

Station2600 = Station;
Station2600.DlFreq = 2600;

distance = linspace(20, 3000, 30);
N = length(distance);
resultsSuburban = NaN(N,2);
resultsUrban = NaN(N,2);
results3gpp900 = NaN(N,2);
results3gpp1800 = NaN(N,2);
results3gpp2600 = NaN(N,2);
for distanceIdx = 1:N
  ue = User;
  bs = Station;
  
  % Set user position to distance away from BS
	% LOS based
  xDiff = bs.Position(1)+distance(distanceIdx); %in M
  ue.Position = [xDiff, bs.Position(2), 1.5];

  % Traverse channel suburban
  %[~, ue] = ChSuburban.traverse(bs,ue,'downlink');
  %resultsSuburban(distanceIdx,1) = ue.Rx.SNRdB;
  %resultsSuburban(distanceIdx,2) = ue.Rx.RxPwdBm;
	
	% Urban
  %[~, ue] = ChUrban.traverse(bs,ue,'downlink');
  %resultsUrban(distanceIdx,1) = ue.Rx.SNRdB;
  %resultsUrban(distanceIdx,2) = ue.Rx.RxPwdBm;
  
  [~, ue] = Ch3gppUMa.traverse(Station900,ue,'downlink');
  results3gpp900(distanceIdx,1) = ue.Rx.ChannelConditions.BaseLoss;
  results3gpp900(distanceIdx,2) = ue.Rx.ChannelConditions.IndoorLoss;
  
    [~, ue] = Ch3gppUMa.traverse(Station1800,ue,'downlink');
  results3gpp1800(distanceIdx,1) = ue.Rx.ChannelConditions.BaseLoss;
  results3gpp1800(distanceIdx,2) = ue.Rx.ChannelConditions.IndoorLoss;
  
      [~, ue] = Ch3gppUMa.traverse(Station2600,ue,'downlink');
  results3gpp2600(distanceIdx,1) = ue.Rx.ChannelConditions.BaseLoss;
  results3gpp2600(distanceIdx,2) = ue.Rx.ChannelConditions.IndoorLoss;
	
  sonohilog(sprintf('%s/%s',int2str(distanceIdx),int2str(N)));

end

figure
plot(distance, results3gpp900(:,1)+ results3gpp900(:,2),'k-.o')
hold on
plot(distance, results3gpp900(:,1),'k-x')
plot(distance, results3gpp1800(:,1)+ results3gpp1800(:,2),'r-.o','Color', [0.843, 0.376, 0.376])
plot(distance, results3gpp1800(:,1),'r-x', 'Color', [0.843, 0.376, 0.376])
plot(distance, results3gpp2600(:,1)+ results3gpp2600(:,2),'g-.o','Color', [0.419, 0.8, 0.517])
plot(distance, results3gpp2600(:,1),'g-x', 'Color', [0.419, 0.8, 0.517])
title('3GPP 38901 UMa')
xlabel('Distance [m]')
ylabel('Average Loss [dB]')
legend('900 MHz O2I','900 MHz Outdoor','1800 MHz O2I','1800 MHz Outdoor', '2600 MHz O2I','2600 MHz Outdoor')
grid on

% 
% figure
% plot(distance, resultsSuburban(:,1))
% hold on
% plot(distance, resultsUrban(:,1))
% plot([0 distance(end)],[4, 4],'r--')
% legend('ITUR1546 Suburban','ITUR1546 Urban', '4 dB')
% xlabel('Distance [m]')
% ylabel('SNR [dB]')
% grid on
% 
% figure
% plot(distance, resultsSuburban(:,2))
% hold on
% plot(distance, resultsUrban(:,2))
% xlabel('Distance [m]')
% ylabel('Received Power [dBm]')
% legend('ITUR1546 Suburban','ITUR1546 Urban')
% grid on
