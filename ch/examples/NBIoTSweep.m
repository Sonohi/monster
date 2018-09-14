clear all
close all
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
Param.numUsers = 1;
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



distance = linspace(20, 5000, 500);
N = length(distance);
resultsSuburban = NaN(N,2);
resultsUrban = NaN(N,2);
for distanceIdx = 1:N
  
  ue = User;
  bs = Station;
  
  % Set user position to distance away from BS
	% LOS based
  xDiff = bs.Position(1)+distance(distanceIdx); %in M
  ue.Position = [xDiff, bs.Position(2), 1.5];

  % Traverse channel suburban
  [~, ue] = ChSuburban.traverse(bs,ue,'downlink');
  resultsSuburban(distanceIdx,1) = ue.Rx.SNRdB;
	resultsSuburban(distanceIdx,2) = ue.Rx.RxPwdBm;
	
	% Urban
  [~, ue] = ChUrban.traverse(bs,ue,'downlink');
  resultsUrban(distanceIdx,1) = ue.Rx.SNRdB;
	resultsUrban(distanceIdx,2) = ue.Rx.RxPwdBm;
	
  sonohilog(sprintf('%s/%s',int2str(distanceIdx),int2str(N)));

end

figure
plot(distance, resultsSuburban(:,1))
hold on
plot(distance, resultsUrban(:,1))
plot([0 distance(end)],[4, 4],'r--')
legend('ITUR1546 Suburban','ITUR1546 Urban', '4 dB')
xlabel('Distance [m]')
ylabel('SNR [dB]')
grid on

figure
plot(distance, resultsSuburban(:,2))
hold on
plot(distance, resultsUrban(:,2))
xlabel('Distance [m]')
ylabel('Received Power [dBm]')
legend('ITUR1546 Suburban','ITUR1546 Urban')
grid on
