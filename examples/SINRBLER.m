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
Config.Channel.losMethod = '3GPP38901-probability';
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0;
Config.Scheduling.absMask = [1,0,1,0,0,0,0,0,0,0];
Config.Channel.fadingActive = true;
Config.Channel.perfectSynchronization = true;

Config.setupNetworkLayout();
%Create used objects
Station = setupStations(Config);
User = setupUsers(Config);
User.Position = [190, 295,1.5];

Channel = setupChannel(Station, User, Config);

%Run for a number of rounds
%seed = 0; %set seed to reproduce simulations
%rng(seed);
nRounds = 1e4; %number of SINR's to check.
nMeasurements = 1e2;
BERtemp = zeros(1,nRounds);
BER = zeros(1, nMeasurements);
BLERtemp = zeros(1,nRounds);
BLER = zeros(1,nMeasurements);
SINRdB = linspace(-2.5,-1,nMeasurements);
SINR = 10.^((SINRdB)./10);

Station.NSubframe = 1;
%Generate traffic

for iMeasurement = 1:nMeasurements
    Config.Runtime.seed = iMeasurement;
    [Traffic, User] = setupTraffic(User, Config);
    %Homemade traffic generation:
    % Traffic = struct();
    % Traffic.Id = 1;
    % Traffic.Type='fullbuffer';
    %TODO: make this the correct format
    % Traffic.TrafficSource = ltePRBS(iMeasurement,600);%%Continure here???
    % Traffic.ArrivalMode = Config.Traffic.arrivalDistribution;
	% Traffic.AssociatedUeIds = AssociatedUeIds;
	% Traffic.ArrivalTimes = Traffic.setArrivalTimes(Config);
    % User.Traffic.generatorId = trafficGenAllocation(1);
	% User.Traffic.startTime = Traffic(trafficGenAllocation(1)).getStartingTime(User.NCellID);
for iRound = 1:nRounds
    Config.Runtime.currentRound = iRound;
    Config.Runtime.currentTime = iRound*10e-3;  
    Config.Runtime.remainingTime = (Config.Runtime.totalRounds - Config.Runtime.currentRound)*10e-3;
    Config.Runtime.remainingRounds = Config.Runtime.totalRounds - Config.Runtime.currentRound - 1;
    % Update Channel property
    Channel.setupRound(Config.Runtime.currentRound, Config.Runtime.currentTime);

    %Associate user
    [User Station] = refreshUsersAssociation(User, Station, Channel, Config);

    
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
    Channel.ChannelModel.TempSignalVariables.RxSINR = SINR(iMeasurement);
    N0 = Channel.ChannelModel.computeSpectralNoiseDensity(Station, 'downlink');
    
    User.Rx.WaveformInfo = Station.Tx.WaveformInfo;
    User.Rx.RxPwdBm = -30;


    
        % Add AWGN
        noise = N0*complex(randn(size(Station.Tx.Waveform)), randn(size(Station.Tx.Waveform)));
        rxSig = Station.Tx.Waveform + noise;
        
        %copy waveform to Rx module
        User.Rx.Waveform = rxSig;

        %Recieve downlink
        %User.downlinkReception(Station, Channel.Estimator.Downlink);
        %Recieve downlink (skipped offset allways gives errors)
        User.Rx.referenceMeasurements(Station);
        User.Rx.demodulateWaveform(Station);
        
        if User.Rx.Demod 
        % Estimate the channel
        User.Rx.estimateChannel(Station, Channel.Estimator.Downlink);
        
        % Apply equalization
        User.Rx.equaliseSubframe();
        
        % Select CQI
        User.Rx.selectCqi(Station);

        % Extract PDSCH
        User.Rx.estimatePdsch(Station);

        % Calculate EVM
        User.Rx.calculateEvm(Station);

        % Log block reception
        User.Rx.logBlockReception();
    else
        %monsterLog(sprintf('(UE RECEIVER MODULE - downlinkReception) not able to demodulate Station(%i) -> User(%i)...',Station.NCellID, User.NCellID),'WRN');
        User.Rx.logNotDemodulated();
        User.Rx.CQI = 3;

    end

        %Data decoding
        User.downlinkDataDecoding(Config);

        %Find BLER
        BLERtemp(iRound) = User.Rx.Blocks.err;
    
    %Compare the transmitted and original data to find errors

    tbRx = User.Rx.TransportBlock;
    tbTx = User.TransportBlock;
    if ~isempty(tbRx) && ~isempty(tbTx)
         [diff, BERtemp(iRound)] = biterr(tbRx, tbTx);
    end
    %TODO: Changin subframes gives offset error and crashes simulation. Fix that
    Station.NSubframe = mod(iRound +1,10);
    User.reset();
end
    BER(iMeasurement) = mean(BERtemp);
    BLER(iMeasurement)=mean(BLERtemp);
    
    %TODO: make actual usefull outputs
end
figure;
semilogx(SINR,BLER);
figure;
xlabel('SNR [dB]');
ylabel('BLER');
semilogy(SINRdB,BLER);