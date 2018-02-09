classdef sonohiWINNER

    properties
        WconfigLayout; % Layout of winner model
        WconfigParset; % Model parameters
        numRx; % Number of receivers, per model
        h; % Stored impulse response
        Channel;
        AA;
        Chtype; %Downlink or Uplink
    end

    methods

        function obj = sonohiWINNER(Stations, Users, Channel, Chtype)
            sonohilog('Initializing WINNER II channel model...','NFO0')
            obj.Channel = Channel;
            obj.Chtype = Chtype;
            classes = unique({Stations.BsClass});
            for class = 1:length(classes)
                varname = classes{class};
                types.(varname) = find(strcmp({Stations.BsClass},varname));

            end

            Snames = fieldnames(types);

            obj.WconfigLayout = cell(numel(Snames),1);
            obj.WconfigParset = cell(numel(Snames),1);


            for model = 1:numel(Snames)
                type = Snames{model};
                stations = [Stations(types.(Snames{model})).NCellID];
                
                [~,users] = obj.Channel.getAssociated(Stations(ismember([Stations.NCellID],stations)),Users);
             
                users = [users.NCellID];
                numLinks = length(users);

                if isempty(users)
                    % If no users are associated, skip the model
                    continue
                end
                [AA, eNBIdx, userIdx] = sonohiWINNER.configureAA(type,stations,users);

                range = max(Channel.Area);

                obj.WconfigLayout{model} = obj.initializeLayout(userIdx, eNBIdx, numLinks, AA, range);

                obj.WconfigLayout{model} = obj.addAssociated(obj.WconfigLayout{model} ,stations,users);

                obj.WconfigLayout{model} = obj.setPositions(obj.WconfigLayout{model} ,Stations,Users);


                obj.WconfigLayout{model}.Pairing = Channel.getPairing(Stations(ismember([Stations.NCellID],obj.WconfigLayout{model}.StationIdx)));

                obj.WconfigLayout{model}  = obj.updateIndexing(obj.WconfigLayout{model} ,Stations);

                obj.WconfigLayout{model}  = obj.setPropagationScenario(obj.WconfigLayout{model} ,Stations,Users, Channel);

                obj.WconfigParset{model}  = obj.configureModel(obj.WconfigLayout{model},Stations);
                
                % Instead of removing the stochastic nature of the winner
                % model, the seed is used for initializing the seed of the
                % winner ensuring a somewhat stochastic process but with
                % reproducable results.
                rng(obj.Channel.Seed);
                obj.WconfigParset{model}.RandomSeed = randi(999);

            end

        end

        function obj = setup(obj)
            % Computes impulse response of initalized winner model
            for model = 1:length(obj.WconfigLayout)

                if isempty(obj.WconfigParset{model})
                    % No users associated, skip the model.
                    continue
                end
                wimCh = comm.WINNER2Channel(obj.WconfigParset{model}, obj.WconfigLayout{model});
                chanInfo = info(wimCh);
                numTx    = chanInfo.NumBSElements(1);
                Rs       = chanInfo.SampleRate(1);
                obj.numRx{model} = chanInfo.NumLinks(1);
                impulseR = [ones(1, numTx); zeros(obj.WconfigParset{model}.NumTimeSamples-1, numTx)];
                h{model} = wimCh(impulseR);
            end
            obj.h = h;



        end

        function [users] = downlink(obj,Stations,Users)
            users = Users;
            for model = 1:length(obj.WconfigLayout)

                if isempty(obj.WconfigLayout{model})
                    sonohilog(sprintf('Nothing assigned to %i model',model),'NFO0')
                    continue
                end
                for link = 1:obj.numRx{model}

                    StationId = obj.WconfigLayout{model}.Pairing(1,link);
                    UserId = obj.WconfigLayout{model}.UserIdx(obj.WconfigLayout{model}.Pairing(2,link)-max(obj.WconfigLayout{model}.Pairing(1,:)));
                    Station = Stations(ismember([Stations.NCellID],obj.WconfigLayout{model}.StationIdx(StationId)));
                    User = users([users.NCellID] == UserId);
                    % Get corresponding TxSig
                    txSig = [Station.Tx.Waveform;zeros(25,1)];
                    txPw = 10*log10(bandpower(txSig));

                    rxSig = obj.addFading(txSig,obj.h{model}{link});

                    rxPw_ = 10*log10(bandpower(rxSig));
                    lossdB = txPw-rxPw_;
                    %plot(10*log10(abs(fftshift(fft(rxSig)).^2)));
                    %plot(10*log10(abs(fftshift(fft(rxSig2{1}))).^2));

                    % Normalize signal and add loss as AWGN based on
                    % noise floor
                    rxSigNorm = rxSig.*10^(lossdB/20);
                    [rxSigNorm, SNRLin, RxPwdBm] = obj.addPathlossAwgn(Station, User, rxSigNorm, lossdB);

                    %plot(10*log10(abs(fftshift(fft(rxSigNorm)).^2)),'Color',[0.5,0.5,0.5,0.2]);

                    User.Rx.SNR = SNRLin;
                    User.Rx.RxPwdBm = RxPwdBm;
                    User.Rx.Waveform = rxSigNorm;
                    User.Rx.PropDelay = obj.Channel.getDistance(Station.Position,User.Position);


                    users([Users.NCellID] == UserId) = User;
                end
            end
        end

        function [stations] = uplink(obj,Stations,Users)
            stations = Stations;
            for model = 1:length(obj.WconfigLayout)

                if isempty(obj.WconfigLayout{model})
                    sonohilog(sprintf('Nothing assigned to %i model',model),'NFO0')
                    continue
                end
                for link = 1:obj.numRx{model}

                    StationId = obj.WconfigLayout{model}.Pairing(1,link);
                    UserId = obj.WconfigLayout{model}.UserIdx(obj.WconfigLayout{model}.Pairing(2,link)-max(obj.WconfigLayout{model}.Pairing(1,:)));
                    Station = Stations(ismember([Stations.NCellID],obj.WconfigLayout{model}.StationIdx(StationId)));
                    User = users([users.NCellID] == UserId);
                    % Get corresponding TxSig
                    txSig = [User.Tx.Waveform;zeros(25,1)];
                    txPw = 10*log10(bandpower(txSig));

                    rxSig = obj.addFading(txSig,obj.h{model}{link});

                    rxPw_ = 10*log10(bandpower(rxSig));
                    lossdB = txPw-rxPw_;
                    %plot(10*log10(abs(fftshift(fft(rxSig)).^2)));
                    %plot(10*log10(abs(fftshift(fft(rxSig2{1}))).^2));

                    % Normalize signal and add loss as AWGN based on
                    % noise floor
                    rxSigNorm = rxSig.*10^(lossdB/20);
                    [rxSigNorm, SNRLin, RxPwdBm] = obj.addPathlossAwgn(User, Station, rxSigNorm, lossdB);

                    %plot(10*log10(abs(fftshift(fft(rxSigNorm)).^2)),'Color',[0.5,0.5,0.5,0.2]);

                    Station.Rx.SNR = SNRLin;
                    Station.Rx.RxPwdBm = RxPwdBm;
                    Station.Rx.Waveform = rxSigNorm;


                    stations([Stations.NCellID] == StationId) = Station;
                end
            end

        end
        

        function [stations,users] = run(obj,Stations,Users, varargin)
        try
        switch obj.Chtype
            case 'downlink'
                users = obj.downlink(Stations,Users);
                stations = Stations;
            case 'uplink'
                stations = obj.uplink(Stations,Users);
                users = Users;
        end

        catch ME
            sonohilog('Something went wrong in the channel... No metrics saved.','WRN')
            stations = Stations
            users = Users
        end

        end

        function [rxSig, SNRLin, rxPwdBm] = addPathlossAwgn(obj, TxNode, RxNode, txSig, lossdB)
            % Compute thermalnoise based on bandwidth
            if isprop(TxNode,'NDLRB') % Station is TxNode
                thermalNoise = obj.Channel.ThermalNoise(TxNode.NDLRB);
            elseif isprop(TxNode,'NULRB')
                thermalNoise = obj.Channel.ThermalNoise(TxNode.NULRB);
            end
            % Get distance of Tx - Rx
            distance = obj.Channel.getDistance(TxNode.Position,RxNode.Position)/1e3;

            % Get transmission power
            txPw = 10*log10(TxNode.getTransmissionPower)+30; %dBm.
            
            % Setup link budget
            rxPwdBm = txPw-lossdB; %dBm
            % SNR = P_rx_db - P_noise_db
            rxNoiseFloor = 10*log10(thermalNoise)+RxNode.Rx.NoiseFigure;
            SNR = rxPwdBm-rxNoiseFloor;
            SNRLin = 10^(SNR/10);
            str1 = sprintf('Node(%i) to Node(%i)\n Distance: %s\n SNR:  %s\n',...
                TxNode.NCellID,RxNode.NCellID,num2str(distance),num2str(SNR));
            sonohilog(str1,'NFO0');

            %% Apply SNR

            % Compute average symbol energy
            % This is based on the number of useed subcarriers.
            % Scale it by the number of used RE since the power is
            % equally distributed
            Es = sqrt(2.0*TxNode.CellRefP*double(TxNode.Tx.WaveformInfo.Nfft) * ...
							TxNode.Tx.WaveformInfo.OfdmEnergyScale);

            % Compute spectral noise density NO
            N0 = 1/(Es*SNRLin);

            % Add AWGN

            noise = N0*complex(randn(size(txSig)), ...
                randn(size(txSig)));

            rxSig = txSig + noise;


        end
    
    end
    
    methods(Static)

        function rx = addFading(tx,h)
            H = fft(h,length(tx));
            % Apply transfer function to signal
            X = fft(tx)./length(tx);
            Y = X.*H;
            rx = ifft(Y)*length(tx);
        end

        function [AA, eNBIdx, userIdx] = configureAA(type,stations,users)

            % Select antenna array based on station class.
            % TODO: load antenna arrays from MAT file. computational hack.
            if strcmp(type,'macro')
                if ~exist('macroAA.mat')
                  Az = -180:179;
                  pattern(1,:,1,:) = winner2.dipole(Az,10);
                  AA(1) = winner2.AntennaArray( ...
                     'ULA', 12, 0.15, ...
                     'FP-ECS', pattern, ...
                     'Azimuth', Az);
                  save('macroAA.mat','AA')
                else
                  sonohilog('Loading pregenerated antenna AA...','NFO0')
                  load('macroAA.mat');
                end
                %AA(1) = winner2.AntennaArray('UCA', 8,  0.2);
            elseif strcmp(type,'micro')
              if ~exist('microAA.mat')
                Az = -180:179;
                pattern(1,:,1,:) = winner2.dipole(Az,10);
                AA(1) = winner2.AntennaArray( ...
                   'ULA', 6, 0.15, ...
                   'FP-ECS', pattern, ...
                   'Azimuth', Az);
                save('microAA.mat','AA')
              else
                sonohilog('Loading pregenerated antenna AA...','NFO0')
                load('microAA.mat');
              end
                %AA(1) = winner2.AntennaArray('UCA', 4,  0.15);
            else

                sonohilog(sprintf('Antenna type for %s BsClass not defined, defaulting...',type),'WRN')
                AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
            end

            % User antenna array

            if ~exist('UEAA.mat')
              ueAA = winner2.AntennaArray('ULA', 1,  0.05);
              save('UEAA.mat','ueAA')
              AA(2) = ueAA;
            else
              sonohilog('Loading pregenerated antenna AA...','NFO0')
              load('UEAA.mat')
              AA(2) = ueAA;
            end


            % Number of sectors.
            numSec = 1;
            eNBIdx = cell(length(stations),1);
            for iStation = 1:length(stations)
                eNBIdx{iStation} = [ones(1,numSec)];
            end
            % For users use antenna configuration 2
            userIdx = repmat(2,1,length(users));

        end

        function cfgLayout =initializeLayout(useridx, eNBidx, numLinks, AA, range)
            % Initialize layout struct by antenna array and number of
            % links.
            cfgLayout = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);

        end

        function cfgLayout = addAssociated(cfgLayout, stations, users)
            % Adds the index of the stations and users associated, e.g.
            % how they link with the station and user objects.
            cfgLayout.StationIdx = stations;
            cfgLayout.UserIdx = users;

        end


        function cfgLayout = setPositions(cfgLayout, Stations, Users)
            % Set the position of the base station
            for iStation = 1:length(cfgLayout.StationIdx)
                cfgLayout.Stations(iStation).Pos(1:3) = int64(floor(Stations([Stations.NCellID] == cfgLayout.StationIdx(iStation)).Position(1:3)));
            end

            % Set the position of the users
            % TODO: Add velocity vector of users
            for iUser = 1:length(cfgLayout.UserIdx)
                cfgLayout.Stations(iUser+length(cfgLayout.StationIdx)).Pos(1:3) = int64(ceil(Users([Users.NCellID] == cfgLayout.UserIdx(iUser)).Position(1:3)));
            end

        end

        function cfgLayout =updateIndexing(cfgLayout,Stations)
            % Change useridx of pairing to reflect
            % cfgLayout.Stations, e.g. If only one station, user one is
            % at cfgLayout.Stations(2)
            % This is to accomondate the mapping needed by winner which is
            % dependent on the cfgLayout.Stations struct. 
            for ll = 1:length(cfgLayout.Pairing(1,:))
              [~,idx] = find(cfgLayout.StationIdx==cfgLayout.Pairing(1,ll));
              cfgLayout.Pairing(1,ll) = idx;
            end
            
            for ll = 1:length(cfgLayout.Pairing(2,:))
                [~,idx] = find(cfgLayout.UserIdx==cfgLayout.Pairing(2,ll));
                cfgLayout.Pairing(2,ll) =  max(cfgLayout.Pairing(1,:))+idx;
            end


        end

        function cfgLayout = setPropagationScenario(cfgLayout, Stations, Users, Ch)
            numLinks = length(cfgLayout.Pairing(1,:));

            for i = 1:numLinks
                userIdx = cfgLayout.UserIdx(cfgLayout.Pairing(2,i)-max(cfgLayout.Pairing(1,:)));
                stationNCellId =  cfgLayout.StationIdx(cfgLayout.Pairing(1,i));
                cBs = Stations([Stations.NCellID] == stationNCellId);
                cMs = Users([Users.NCellID] == userIdx);
                % Apparently WINNERchan doesn't compute distance based
                % on height, only on x,y distance. Also they can't be
                % doubles...
                distance = Ch.getDistance(cBs.Position(1:2),cMs.Position(1:2));
                if cBs.BsClass == 'micro'

                    if distance <= 20
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B1 with LOS, swapping to B4 LOS',...
                            stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');

                        cfgLayout.ScenarioVector(i) = 6; % B1 Typical urban micro-cell
                        cfgLayout.PropagConditionVector(i) = 1; %1 for LOS

                    elseif distance <= 50
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B1 with NLOS, swapping to B1 LOS',...
                            stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');

                        cfgLayout.ScenarioVector(i) = 3; % B1 Typical urban micro-cell
                        cfgLayout.PropagConditionVector(i) = 1; %1 for LOS
                    else
                        cfgLayout.ScenarioVector(i) = 3; % B1 Typical urban micro-cell
                        cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                    end
                elseif cBs.BsClass == 'macro'
                    if distance < 50
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for C2 NLOS, swapping to LOS',...
                            stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');
                        cfgLayout.ScenarioVector(i) = 11; %
                        cfgLayout.PropagConditionVector(i) = 1; %
                    else
                        cfgLayout.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
                        cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                    end
                end


            end

        end

        function cfgModel = configureModel(cfgLayout,Stations)
            % Use maximum fft size
            % However since the same BsClass is used these are most
            % likely to be identical
            sw_tx = [Stations(ismember([Stations.NCellID],cfgLayout.StationIdx)).Tx];
            sw_info = [sw_tx.WaveformInfo];
            swNfft = [sw_info.Nfft];
            swSamplingRate = [sw_info.SamplingRate];
            cf = max([Stations(ismember([Stations.NCellID],cfgLayout.StationIdx)).DlFreq]); % Given in MHz

            frmLen = double(max(swNfft));   % Frame length

            % Configure model parameters
            % TODO: Determine maxMS velocity
            maxMSVelocity = max(cell2mat(cellfun(@(x) norm(x, 'fro'), ...
                {cfgLayout.Stations.Velocity}, 'UniformOutput', false)));


            cfgModel = winner2.wimparset;
            cfgModel.CenterFrequency = cf*10e5; % Given in Hz
            cfgModel.NumTimeSamples     = frmLen; % Frame length
            cfgModel.IntraClusterDsUsed = 'yes';   % No cluster splitting
            cfgModel.SampleDensity      = max(swSamplingRate)/50;    % To match sampling rate of signal
            cfgModel.PathLossModelUsed  = 'yes';  % Turn on path loss
            cfgModel.ShadowingModelUsed = 'yes';  % Turn on shadowing
            cfgModel.SampleDensity = round(physconst('LightSpeed')/ ...
                cfgModel.CenterFrequency/2/(maxMSVelocity/max(swSamplingRate)));

        end
        



    end

end
