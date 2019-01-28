clear all
close all
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
Param.numUsers = 1;
Param.posScheme = 'None';
Param.draw = 0;
Param.schRounds = 300;
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';
Param.channel.enableShadowing = true;
Param.channel.enableFading = true;
Param.channel.InterferenceType = 'None';
Param.channel.enableReciprocity = false;
Param.channel.perfectSynchronization = true;


if Param.draw
	Param = createLayoutPlot(Param);
	Param = createPHYplot(Param);
end

% Create Stations and Users
[Station, Param] = createBaseStations(Param);
User = createUsers(Param);

% Create Channel scenario
Channel = MonsterChannel(Station, User, Param);
ChannelEstimator = createChannelEstimator();

Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

%% Downlink
downlink_cqi = nan(Param.schRounds,1);
uplink_csi = nan(Param.schRounds, 300, 14);
uplink_noise_est = nan(Param.schRounds,1);
uplink_snr_calc = nan(Param.schRounds,1);
UserDistance = 100;
figure
for subframe = 1:Param.schRounds
	
	Station.NSubframe = subframe-1;
	Station.Tx.createReferenceSubframe();
	Station.Tx.assignReferenceSubframe();
	%Station.Tx.plotSpectrum();
	User.NSubframe = subframe-1;
	User.Position(1:2) = Station.Position(1:2) + [UserDistance, 0];
	% Traverse channel
	Channel.iRound = subframe-1;
	Channel.traverse(Station,User,'downlink');

	%h(:,subframe) = Channel.ChannelModel.getImpulseResponse('downlink', [], []);
	h_downlink(:,subframe) = Channel.ChannelModel.getPathGains();
	Channel.ChannelModel.clearTempVariables();

	%User.Rx.plotSpectrum()
  User.Rx.receiveDownlink(Station, ChannelEstimator.Downlink);
  
	% Print
	fprintf("Subframe %i Downlink CQI: %i \n", subframe-1, User.Rx.CQI)
	downlink_cqi(subframe) = User.Rx.CQI;
	downlink_snr(subframe) = User.Rx.SNRdB;
	downlink_noiseest(subframe) = User.Rx.NoiseEst;
	downlink_sinrs(subframe,:) = User.Rx.SINRS;
	%% Uplink
	User.Tx = User.Tx.mapGridAndModulate(User, Param);
	
	Station.setScheduleUL(Param);
	
	%User.Tx.plotSpectrum()
	%User.Tx.plotResources()
	
	% Traverse channel uplink
	Channel.traverse(Station,User,'uplink');
	h_uplink(:,subframe) = Channel.ChannelModel.getPathGains();
	
 	uplink_snr_calc(subframe,:) = 10*log10(Station.Rx.ReceivedSignals{1}.SNR);
% 	Station.Rx.createReceivedSignal()
% 	
% 	
% 	%Station.Rx.plotSpectrums()
% 	%Station.Rx.plotResources()
% 	
% 	% TODO: move this to Rx module logic
% 	testSubframe = lteSCFDMADemodulate(struct(User), Station.Rx.Waveform);
% 	[EstChannelGrid, uplink_noise_est(subframe,:)] = lteULChannelEstimate(struct(User), User.Tx.PUSCH, ChannelEstimator.Uplink, testSubframe);
% 	[EqGrid, uplink_csi(subframe,:,:)] = lteEqualizeMMSE(testSubframe, EstChannelGrid, uplink_noise_est(subframe,:));
	
end
figure
plot(10*log10(abs(h_downlink(1,:))))
hold on
plot(10*log10(abs(h_uplink(1,:))))
%save(sprintf('DownlinkCQI_uplinkCSI_%im_%isubframes_300e-9deplaySpread_0doppler.mat',UserDistance,Param.schRounds),'downlink_cqi', 'downlink_noiseest','downlink_sinrs','downlink_snr','uplink_csi', 'uplink_snr_calc');
figure
plot(10*log10(abs(h_uplink(1,:))), 10*log10(abs(h_downlink(1,:))),'o')


% figure
% plot(10*log10(uplink_noise_est), 10*log10(downlink_noiseest),'o')
% xlabel('Estimated uplink \sigma^2')
% ylabel('Estimated downlink \sigma^2')
% 
% figure
% subplot(2,1,1)
% mesh(abs(User.Rx.CSI))
% 
% figure
% ylim([min(min(min(abs(squeeze(uplink_csi(:,:,:)))))), max(max(max(abs(squeeze(uplink_csi(:,:,:))))))])
% for subframe = 1:Param.schRounds
% 	mesh(abs(squeeze(uplink_csi(subframe,:,:))))
% 	
% 	drawnow;
% 	pause(0.1)
% end
% 
% figure
% subplot(2,1,1)
% mesh(abs(User.Rx.EqSubframe))
% subplot(2,1,2)
% mesh(abs(EqGrid))
% 
% figure
% yyaxis left
% plot(downlink_cqi)
% ylim([0 16])
% ylabel('CQI')
% hold on
% yyaxis right
% plot(downlink_snr)
% plot(downlink_noiseest,'o')
% plot(downlink_sinrs(:,1))
% plot(20*log10(1./uplink_noise_est(:,1)),'*')
% plot(uplink_snr_calc(:,1),'<')
% minSNR = min([min(downlink_snr), min(downlink_noiseest), min(downlink_sinrs)]);
% ylabel('SNR (dB)')
% xlabel('Subframe #')
% ylim([minSNR-10 40])
% legend('Downlink CQI', 'Calculated SNR', 'Estimated SNR', 'Equalizer wideband SNR')
% 
% 
% legend('TDL-C profile', 'TDL-A profile', 'no fading')
% xlabel('Subframe #')
% ylabel('CQI downlink')
% ylim([0 16])
% 
% 
% figure
