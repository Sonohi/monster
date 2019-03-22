%clear all
%close all

Config = MonsterConfig();

% Make local changes
Config.SimulationPlot.runtimePlot = 0;
Config.Ue.number = 1;
Config.MacroEnb.number = 1;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;
Config.Channel.shadowingActive = false;
Config.Channel.losMethod = '3GPP38901-probability';
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0;
Config.Scheduling.absMask = [1,0,1,0,0,0,0,0,0,0];
Config.Channel.fadingActive = false;
Config.Channel.perfectSynchronization = true;
config.Runtime.totalRounds = 1;

Config.setupNetworkLayout();
%Create used objects
Station = setupStations(Config);
Station.Tx.PDSCH.CSIMode = 'PUCCH 1-1';
Station.Tx.PDSCH.RVSeq = [0 0 1 2];
User = setupUsers(Config);
User.Position = [190, 295,1.5];

Channel = setupChannel(Station, User, Config);

%Choice of MCS and their SINR range of interrest [dB]
MCSlevels=[1 3 4 6 7 9 11 13 15 20 21 22 24 26 28];
SINRlevels=[-5.2 -3.5 -2.5 -1 0.2 1.7 4.2 6 7.4 12 12.5 13 15 17.5 17;
             -4 -2.25 -1.5 0.2 1.2 2.7 5.2 7 9.5 16 17 18 20 30 30];

%Create a figure for plotting
figure;
hold on;

%Run for a number of rounds
nRounds = 1e2; 
nMeasurements = 10; %number of SINR's to check.
BERtemp = zeros(1,nRounds);
BER = zeros(1, nMeasurements);
BLERtemp = zeros(1,nRounds);
BLER = zeros(1,nMeasurements);

for iMCS=1:length(MCSlevels)
    
    SINRdB = linspace(SINRlevels(1,iMCS),SINRlevels(2,iMCS),nMeasurements);
    SINR = 10.^((SINRdB)./10); %Convert to W
    MCS = MCSlevels(iMCS); %Chosen MCS
    Station.NSubframe = 1; %Starting subframe
    %Check for data file for selected MCS level.
    filestr = sprintf('MCS%d.mat',MCSlevels(iMCS));
    if ~exist(filestr)
        %Make new calculation
        for iMeasurement = 1:nMeasurements
            Config.Runtime.seed = iMeasurement;
            [Traffic, User] = setupTraffic(User, Config);
        
            for iRound = 1:nRounds
                Config.Runtime.currentRound = iRound;
                Config.Runtime.currentTime = iRound*10e-3;  
                Config.Runtime.remainingTime = (Config.Runtime.totalRounds - Config.Runtime.currentRound)*10e-3;
                Config.Runtime.remainingRounds = Config.Runtime.totalRounds - Config.Runtime.currentRound - 1;
                
                % Update Channel property
                Channel.setupRound(Config.Runtime.currentRound, Config.Runtime.currentTime);

                %Associate user 
                [User Station] = refreshUsersAssociation(User, Station, Channel, Config);


                %Set MCS
                for i=1:50
                    Station.ScheduleDL(i).Mcs = MCS;
                end
                
                % updateUsersQueues
                UeTrafficGenerator = Traffic([Traffic.Id] == User.Traffic.generatorId);
                User.Queue = UeTrafficGenerator.updateTransmissionQueue(User, iRound);

                %schedule
                Station.evaluateScheduling(User);
                Station.downlinkSchedule(User, Config);

                %setupEnbTransmitters
                User.generateTransportBlockDL(Station, Config);
                User.generateCodewordDL();    
                Station.Tx.setupGrid(iRound);
                Station.setupPdsch(User);
                Station.Tx.modulateTxWaveform();

                %downlinkTraverse
                %Changes are made as this is where the noise is added

                %Add noise to waveform depending on SINR
                Channel.ChannelModel.addAWGNdl(Station, User, SINR(iMeasurement));

                %downlinkUeReception
                User.Rx.computeOffset(Station);
                if User.Rx.Offset >=0
                    User.Rx.applyOffset(Station); 
                end
                User.Rx.referenceMeasurements(Station);
                User.Rx.demodulateWaveform(Station);

                if User.Rx.Demod 
                    % Estimate the channel
                    User.Rx.estimateChannel(Station, Channel.Estimator.Downlink);

                    % Apply equalization
                    User.Rx.equaliseSubframe();

                    % Select CQI
                    User.Rx.selectCqi(Station);
                    %If CQI returns 0, even though it demodulated set CQI to 1
                    if User.Rx.CQI == 0
                        User.Rx.CQI = 1;
                    end

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
            
                Station.NSubframe = mod(iRound +1,10);
                User.reset();
        end
            %Record average BLER
            BER(iMeasurement) = mean(BERtemp);
            BLER(iMeasurement)=mean(BLERtemp);

        end
        %Plot
        semilogy(SINRdB,BLER);
        hold on;
        %Save to save time.
        save(strcat('examples/resultsSINRBLER/',filestr),'SINRdB','BLER');
    else

        load(filestr);
        %load and plot
        semilogy(SINRdB,BLER);
        hold on;
    end


end
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
