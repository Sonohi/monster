clear all
close all
load('SimulationParameters.mat');

%% System setup
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
Param.mobilityScenario = 'pedestrian-indoor';
[Station, Param] = createBaseStations(Param);
User = createUsers(Param);

Param.channel.enableShadowing = true;
Param.channel.LOSMethod = '3GPP38901-probability';
Param.channel.modeDL = '3GPP38901';
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';

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
Station.NDLRB = 6;

% Setup of frequencies

Station900 = Station;
Station900.DlFreq = 900;

Station1800 = Station;
Station1800.DlFreq = 1800;

Station2600 = Station;
Station2600.DlFreq = 2600;

distance = linspace(20, 5000, 30);
N = length(distance);
resultsSuburban = NaN(N,2);
resultsUrban = NaN(N,2);
results3gpp900 = NaN(N,6);
results3gpp1800 = NaN(N,6);
results3gpp2600 = NaN(N,6);

for distanceIdx = 1:N
  ue = User;
  bs = Station;
  
  % Set user position to distance away from BS
	% LOS based
  xDiff = bs.Position(1)+distance(distanceIdx); %in M
  ue.Position = [xDiff, bs.Position(2), 1.5];

  % Compute 900 MHz UMa channel and store results
  [~, ue900] = Ch3gppUMa.traverse(Station900,ue,'downlink');
  results3gpp900(distanceIdx,1) = ue900.Rx.ChannelConditions.BaseLoss;
  results3gpp900(distanceIdx,2) = ue900.Rx.ChannelConditions.IndoorLoss;
  ue900.Rx = ue900.Rx.referenceMeasurements(Station900);
	results3gpp900(distanceIdx,3) = ue900.Rx.SNRdB;
	results3gpp900(distanceIdx,4) = ue900.Rx.RSRQdB;
	results3gpp900(distanceIdx,5) = ue900.Rx.RxPwdBm;
	results3gpp900(distanceIdx,6) = ue900.Rx.ChannelConditions.pathloss;
	
	 % Compute 1800 MHz UMa channel and store results
  [~, ue1800] = Ch3gppUMa.traverse(Station1800,ue,'downlink');
  results3gpp1800(distanceIdx,1) = ue1800.Rx.ChannelConditions.BaseLoss;
  results3gpp1800(distanceIdx,2) = ue1800.Rx.ChannelConditions.IndoorLoss;
	ue1800.Rx = ue1800.Rx.referenceMeasurements(Station1800);
	results3gpp1800(distanceIdx,3) = ue1800.Rx.SNRdB;
	results3gpp1800(distanceIdx,4) = ue1800.Rx.RSRQdB;
	results3gpp1800(distanceIdx,5) = ue1800.Rx.RxPwdBm;
	results3gpp1800(distanceIdx,6) = ue1800.Rx.ChannelConditions.pathloss;
	
   % Compute 2600 MHz UMa channel and store results
  [~, ue2600] = Ch3gppUMa.traverse(Station2600,ue,'downlink');
  results3gpp2600(distanceIdx,1) = ue2600.Rx.ChannelConditions.BaseLoss;
  results3gpp2600(distanceIdx,2) = ue2600.Rx.ChannelConditions.IndoorLoss;
	ue2600.Rx = ue2600.Rx.referenceMeasurements(Station2600);
	results3gpp2600(distanceIdx,3) = ue2600.Rx.SNRdB;
	results3gpp2600(distanceIdx,4) = ue2600.Rx.RSRQdB;
	results3gpp2600(distanceIdx,5) = ue2600.Rx.RxPwdBm;
	results3gpp2600(distanceIdx,6) = ue2600.Rx.ChannelConditions.pathloss;
	
  sonohilog(sprintf('%s/%s',int2str(distanceIdx),int2str(N)));

end

%% Plot of results

figure
plot(distance, results3gpp900(:,1)+ results3gpp900(:,2),'k-.o')
hold on
plot(distance, results3gpp900(:,1),'k-x')
plot(distance, results3gpp1800(:,1)+ results3gpp1800(:,2),'r-.o','Color', [0.843, 0.376, 0.376])
plot(distance, results3gpp1800(:,1),'r-x', 'Color', [0.843, 0.376, 0.376])
plot(distance, results3gpp2600(:,1)+ results3gpp2600(:,2),'g-.o','Color', [0.419, 0.8, 0.517])
plot(distance, results3gpp2600(:,1),'g-x', 'Color', [0.419, 0.8, 0.517])
title(sprintf('3GPP 38901 %s',Param.channel.region.macroScenario))
xlabel('Distance [m]')
ylabel('Average Loss [dB]')
legend('900 MHz O2I','900 MHz Outdoor','1800 MHz O2I','1800 MHz Outdoor', '2600 MHz O2I','2600 MHz Outdoor')
grid on

figure
plot(distance, results3gpp900(:,3),'k-x')
hold on
plot(distance, results3gpp1800(:,3),'-x','Color', [0.843, 0.376, 0.376])
plot(distance, results3gpp2600(:,3),'-x','Color', [0.419, 0.8, 0.517])
title(sprintf('3GPP 38901 %s',Param.channel.region.macroScenario))
xlabel('Distance [m]')
ylabel('SNR [dB]')
legend('900 MHz O2I', '1800 MHz O2I', '2600 MHz O2I')
grid on

figure
plot(distance, results3gpp900(:,5),'k-o')
hold on
plot(distance, results3gpp1800(:,5),'-o','Color',  [0.843, 0.376, 0.376])
plot(distance, results3gpp2600(:,5),'-o','Color', [0.419, 0.8, 0.517])
title(sprintf('3GPP 38901 %s',Param.channel.region.macroScenario))
xlabel('Distance [m]')
ylabel('Received power [dBm]')
legend('900 MHz O2I', '1800 MHz O2I', '2600 MHz O2I')
grid on


figure
plot(distance, results3gpp900(:,6),'k-o')
hold on
plot(distance, results3gpp1800(:,6),'-o','Color',  [0.843, 0.376, 0.376])
plot(distance, results3gpp2600(:,6),'-o','Color', [0.419, 0.8, 0.517])
title(sprintf('3GPP 38901 %s',Param.channel.region.macroScenario))
xlabel('Distance [m]')
ylabel('Total path loss [dB]')
legend('900 MHz O2I', '1800 MHz O2I', '2600 MHz O2I')
grid on