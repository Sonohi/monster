%clear all
%close all


clear all
close all

% Make local changes
Config = MonsterConfig();
Config.SimulationPlot.runtimePlot = 0;
Config.Scenario = 'Single Cell';
Config.MacroEnb.ISD = 300;
Config.MacroEnb.sitesNumber = 1;
Config.MacroEnb.cellsPerSite = 1;
Config.MacroEnb.height = 35;
Config.MicroEnb.sitesNumber = 0;
Config.Channel.fadingActive = false;
Config.Ue.number = 1;
Config.Ue.height = 1.5;
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.arrivalDistribution = 'Static';
Config.Traffic.mix = 0;

Logger = MonsterLog(Config);
Monster = Monster(Config, Logger);
Channel = Monster.Channel;
User = Monster.Users(1);
User.Position = [190, 295,1.5];
Cell = Monster.Cells(1);


%Choice of MCS and their SINR range of interrest [dB]
MCSlevels=[1 3 4 6 7 9 11 13 15 20 21 22 24 26 28];

SINRlevels = linspace(-10, 5, 30);
nMeasurements = 10;

BLER = zeros(length(MCSlevels), length(SINRlevels),nMeasurements);
for iMeas = 1:nMeasurements
Config.Runtime.seed = iMeas;
[Traffic, User] = setupTraffic(User, Config, Logger);
        
Monster.setupRound(0);
for iMCS = 1:length(MCSlevels)
% For each SINR value compute BLER
	for iSINR = 1:length(SINRlevels)
		SINRdB = SINRlevels(iSINR);
		SINR = 10.^((SINRdB)./10);
		%[Traffic, User] = setupTraffic(User, Config, Logger);
		Monster.associateUsers();

		Monster.updateUsersQueues();
		Monster.scheduleDL();
		Monster.setupEnbTransmitters();

		for i=1:50
				Cell.ScheduleDL(i).Mcs = MCSlevels(iMCS);
		end

		% Set SINR
		NoisySignal = MonsterChannel.AddAWGN(Cell, 'downlink', SINR, Cell.Tx.WaveformInfo.Nfft, Cell.Tx.Waveform);
		User.Rx.Waveform = NoisySignal;
		%User.Rx.Waveform = Cell.Tx.Waveform;
		User.Rx.ChannelConditions.WaveformInfo = Cell.Tx.WaveformInfo;
		User.Rx.ChannelConditions.RxPwdBm = -20;

		% Log block error rate
		Monster.downlinkUeReception();
		BLER(iMCS, iSINR, iMeas)= User.Rx.Blocks.err;
		BER(iMCS, iSINR, iMeas) = User.Rx.Bits.ratio;

	end

end
end
figure
semilogy(SINRlevels,mean(BLER,3))
xlabel('SNR [dB]');
ylabel('BLER');
%Add legend
legend('QPSK, CQI=1, MCS=1', 'QPSK, CQI=2, MCS=3','QPSK, CQI=3, MCS=4',...
        'QPSK, CQI=4, MCS=6','QPSK, CQI=5, MCS=7','QPSK, CQI=6, MCS=9',...
        '16QAM, CQI=7, MCS=11','16QAM, CQI=8, MCS=13','16QAM, CQI=9, MCS=15',...
        '64QAM, CQI=10, MCS=20,','64QAM, CQI=11, MCS=21',' 64QAM, CQI=12, MCS=22',...
        '64QAM, CQI=13, MCS=24','64QAM, CQI=14, MCS=26','64QAM, CQI=15, MCS=28',...
        'Location','northeastoutside');
set(gca,'yscale','log');
