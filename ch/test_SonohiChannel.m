%% Setup Station and User and loop configurations
sonohi(1);

Param.numMacro = 1;
Param.numMicro = 0;
Param.macroHeight = 30; %given in meters
Param.microHeight = 25;
Param.ueHeight = 1;
Param.microPos = 'uniform'; % uniform or random
Param.microUniformRadius = 100;
Param.nboRadius = 10;
Param.numSubFramesMacro = 50;
Param.numSubFramesMicro = 25;
Param.numSubFramesUE = 25;
Param.numUsers = 2;
Param.mobilityScenario = 3; %Static
Param.ueNoiseFigure = 7; %Given in dB
Param.bsNoiseFigure = 3; %Given in dB
Param.buildingHeight = 30; %Given in meters
Param.channel.modeDL = 'eHATA';
Param.channel.modeUL = '';
Param.channel.region = 'DenseUrban';
Param.dlFreq = 1842.5; %Given in Mhz
Param.rtxOn = 0; %Disable HARQ
Param.harqProc = 0;
Param.Frames = 10; % LTE frames to simulate
Param.schRounds = Param.Frames*10;%10 rounds per frame
Param.draw = 1;
Param.pucchFormat = 2;
Param.PRACHInterval = 10;
Param.BaseSeed = 42;
Param.handoverTimer = 0.02;
% Setup stuff
Param.buildings = load('mobility/buildings.txt');
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
    max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.buildingHeight],[1 length(Param.buildings(:,1))]);

% Create stations
[Stations, Param.AreaPlot] = createBaseStations(Param);

% Create users
Users = createUsers(Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();


%% start loop
for frame = 1:Param.Frames
    sonohilog(sprintf('Frame %i/%i',frame,Param.Frames),'NFO')
    
    % Associate and schedule user
    simTime = frame*0.01; %one frame is 10ms
    
    [Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param, simTime);
    
    % Copy dummy frame
    for iStation = 1:length(Stations)
        Stations(iStation).Tx.Waveform = Stations(iStation).Tx.Frame;
        Stations(iStation).Tx.WaveformInfo = Stations(iStation).Tx.FrameInfo;
        Stations(iStation).Tx.ReGrid = Stations(iStation).Tx.FrameGrid;
    end
    
    % Traverse channel
    Channel = Channel.setupChannelDL(Stations,Users);
    sonohilog(sprintf('Traversing channel (mode: %s)...',Param.channel.modeDL),'NFO')
    [Stations, Users, ChannelNew] = Channel.traverse(Stations,Users,'downlink');
    
    % Calculate offset (only necessary if fading is used)
    for p = 1:length(Users)
        station = Stations(find([Stations.NCellID] == Users(p).ENodeBID));
        Users(p).Rx.Offset = lteDLFrameOffset(struct(station), Users(p).Rx.Waveform);
    end
    
    % Receive signal
    for iUser = 1:length(Users)
        user = Users(iUser);
        station = Stations([Stations.NCellID] == user.ENodeBID);
        % Apply Offset
        user.Rx.Waveform = user.Rx.Waveform(1+user.Rx.Offset:end,:);
        
        % Try demodulation
        [demodBool, user.Rx] = user.Rx.demodulateWaveform(station);
        % demodulate received waveform, if it returns 1 (true) then demodulated
        if demodBool
            % Conduct reference measurements
            user.Rx = user.Rx.referenceMeasurements(station);
            % Estimate Channel
            user.Rx = user.Rx.estimateChannel(station, ChannelEstimator.Downlink);
            % Equalize signal
            user.Rx = user.Rx.equaliseSubframe();
            % Get PDSCH
            [indPdsch, ~] = station.getPDSCHindicies;
            
            txGrid = station.Tx.ReGrid;
            
            EVM = comm.EVM;
            EVM.AveragingDimensions = [1 2];
            preEqualisedEVM = EVM(txGrid,user.Rx.Subframe);
            fprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', ...
                preEqualisedEVM);
            %EVM of post-equalized receive signal
            postEqualisedEVM = EVM(txGrid,user.Rx.EqSubframe);
            fprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', ...
                postEqualisedEVM);

            if Param.draw
                constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',1, ...
                    'SymbolsToDisplaySource','Property','SymbolsToDisplay',600);
                eqGrid_r = user.Rx.EqSubframe(indPdsch);
                constDiagram(eqGrid_r)
                % Plot the received and equalized resource grids
                hDownlinkEstimationEqualizationResults(user.Rx.Subframe, user.Rx.EqSubframe);
                
            end

            Users(iUser) = user;
        else
            sonohilog(sprintf('Not able to demodulate Station(%i) -> User(%i)...',station.NCellID,user.NCellID),'WRN');
            user.Rx.PostEvm = 100;
            user.Rx.PreEvm = 100;
            user.Rx.CQI = 1;
            Users(iUser) = user;
            continue;
        end
        
        sinr(frame,iUser) = user.Rx.SINRdB;
        rxpw(frame,iUser) = user.Rx.RxPwdBm;
    end
    
    simtime(frame) = simTime;
    
    
    
end



