clear all
%close all

Config = MonsterConfig();


% Make local changes
Config.SimulationPlot.runtimePlot = 0;
Config.Ue.number = 1;
Config.MacroEnb.number = 1;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS';
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0;
Config.Scheduling.absMask = [0,0,1,0,0,0,0,0,0,0];
Config.Channel.fadingActive = 0;
Config.Channel.perfectSynchronization = true;

Config.setupNetworkLayout();
%Create used objects
Station = setupStations(Config);
User = setupUsers(Config);
User.Position = [190, 295,1.5];

Channel = setupChannel(Station, User, Config);

%Run for a number of rounds
seed = 0; %set seed to reproduce simulations
rng(seed);
nRounds = 1e2; %number of SINR's to check.
nMeasurements = 1e1;
BER = zeros(1,nRounds);
BLER = zeros(1,nRounds);
BLERtemp = zeros(1,nMeasurements);
SINRdB = linspace(-1,30,nRounds);
SINR = 10.^((SINRdB)./10);

Station.NSubframe = 1;
for iRound = 1:nRounds

    %Associate user
    [User Station] = refreshUsersAssociation(User, Station, Channel, Config);

    %Generate traffic
    [Traffic, User] = setupTraffic(User, Config);
    UeTrafficGenerator = Traffic([Traffic.Id] == User.Traffic.generatorId);
	User.Queue = UeTrafficGenerator.updateTransmissionQueue(User, iRound);

    %Schedule traffic
    Station.evaluateScheduling(User);
    Station.downlinkSchedule(User, Config);

    %Generate transportblocks
    User.generateTransportBlockDL(Station, Config);
    User.generateCodewordDL();    
    
    
    Station.Tx.setupGrid(1);
    
    Station.setupPdsch(User);

    Station.Tx.modulateTxWaveform();

    %Downlink traverse
    %Channel.traverse(Station, User, 'downlink');
    
    %Add noise to waveform by varying SINR
    
    Nfft = 2^ceil(log2(12*Station.NDLRB/0.85));
    Channel.ChannelModel.TempSignalVariables.RxWaveformInfo.Nfft = Nfft;
    % set SINR
    Channel.ChannelModel.TempSignalVariables.RxSINR = SINR(iRound);
    N0 = Channel.ChannelModel.computeSpectralNoiseDensity(Station, 'downlink');
    
    User.Rx.WaveformInfo = Station.Tx.WaveformInfo;
    User.Rx.RxPwdBm = -30;
    %TODO: several rounds for each SINR

    for iMeasurement = 1:nMeasurements
        % Add AWGN
        noise = N0*complex(randn(size(Station.Tx.Waveform)), randn(size(Station.Tx.Waveform)));
        rxSig = Station.Tx.Waveform + noise;
        
        %copy waveform to Rx module
        User.Rx.Waveform = rxSig;

        %Recieve downlink
        User.downlinkReception(Station, Channel.Estimator.Downlink);

        %Data decoding
        User.downlinkDataDecoding(Config);

        %Find BLER
        BLERtemp(iMeasurement) = User.Rx.Blocks.err;
    end
    %Compare the transmitted and original data to find errors

    % tbRx = User.Rx.TransportBlock;
    % tbTx = User.TransportBlock;
    % if ~isempty(tbRx) && ~isempty(tbTx)
    %     [diff, BER(iRound)] = biterr(tbRx, tbTx);
    % end
    BLER(iRound)=sum(BLERtemp)/nMeasurements;
    %TODO: make actual usefull outputs
end
figure;
semilogx(SINR,BLER);
figure;
semilogy(SINRdB,BLER);