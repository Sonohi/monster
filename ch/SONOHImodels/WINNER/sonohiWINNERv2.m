classdef sonohiWINNERv2 < sonohiBase
    % The main objective of this class is to manipulate variables and structures with that of the WINNER II model which is available standalone, in MATLAB. https://se.mathworks.com/matlabcentral/fileexchange/59690-winner-ii-channel-model-for-communications-system-toolbox
    % 
    % Antenna arrays are per default loaded from .mat files, and any changes to these are reflected.
    % Propagations cenarios are as follows: [1=A1, 2=A2, 3=B1, 4=B2, 5=B3, 6=B4, 7=B5a, 8=B5c, 9=B5f, 10=C1, 11=C2, 12=C3, 13=C4, 14=D1, 15=D2a].
		% 
		% .. warning:: WINNER II is considered some what unstable per 16/05/2018. See issue #67
		%
    % The table of mapping is as follows
    %
    % +-------+----------------------+--------------------------------------+---------------+
    % | Index | Scenario             | Definition                           | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 1     | A1                   | Indoor small office / residential    | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 2     | A2                   | Indoor to outdoor                    | NLOS          |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 3     | B1 Hotspot           | Typical urban micro-cell             | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 4     | B2                   | Bad Urban micro-cell                 | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 5     | B3 Hotspot           | Large indoor hall                    | LOS           |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 6     | B4                   | Outdoor to indoor                    | NLOS          |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 7     | B5a Hotspot Metropol | LOS stat. feeder,                    | LOS           |
    % |       |                      | rooftop to rooftop                   |               |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 8     | B5c Hotspot Metropol | LOS stat. feeder, street-            | LOS           |
    % |       |                      | level to street-leve                 |               |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 9     | B5f                  | Feeder link BS -> FRS.               | LOS/OLOS/NLOS |
    % |       |                      | Approximately RT to RT               |               |
    % |       |                      | leve                                 |               |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 10    | C1 Metropol          | Suburban                             | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 11    | C2 Metropol          | Typical urban macro-cell             | NLOS          |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 12    | C3                   | Bad Urban macro-cell                 | LOS/NLOS      |
    % +-------+----------------------+--------------------------------------+---------------+
    % | 13    | C4                   | Outdoor to indoor (urban) macro-cell | NLOS          |
    % +-------+----------------------+--------------------------------------+---------------+
    % 
    properties
        WconfigLayout % Layout of winner model
        WconfigParset % Model parameters
        numRx % Number of receivers, per model
        h % Stored impulse response
        AA % Antenna arrays
    end

    methods

        function obj = sonohiWINNERv2(Channel, Chtype)
            % The constructor inherits :class:`ch.SONOHImodels.sonohiBase` and does the needed manipulation of data structures to use the WINNER library. This primarily includes a mapping between the WINNER layout/config and the mapping done in MONSTER.
            % For this it needs the following inputs:
            %
            % :param Stations: Station objects with a transmitter and receiver module.
            % :type Stations: :class:`enb.EvolvedNodeB`
            % :param Users: UE objects with a transmitter and receiver module
            % :type Users: :class:`ue.UserEquipment`
            % :param Channel: Channel object
            % :type Channel: :class:`ch.SonohiChannel`
            obj = obj@sonohiBase(Channel, Chtype);
        end

				function obj = setup(obj, Stations, Users)
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
                [AA, eNBIdx, userIdx] = obj.configureAA(type,stations,users);


                obj.WconfigLayout{model} = obj.initializeLayout(userIdx, eNBIdx, numLinks, AA);

                obj.WconfigLayout{model} = obj.addAssociated(obj.WconfigLayout{model} ,stations,users);

                obj.WconfigLayout{model} = obj.setPositions(obj.WconfigLayout{model} ,Stations,Users);


                obj.WconfigLayout{model}.Pairing = obj.Channel.getPairing(Stations(ismember([Stations.NCellID],obj.WconfigLayout{model}.StationIdx)));

                obj.WconfigLayout{model}  = obj.updateIndexing(obj.WconfigLayout{model} ,Stations);

                obj.WconfigLayout{model}  = obj.setPropagationScenario(obj.WconfigLayout{model} ,Stations,Users, obj.Channel);

                obj.WconfigParset{model}  = obj.configureModel(obj.WconfigLayout{model},Stations);
                
                % Instead of removing the stochastic nature of the winner
                % model, the seed is used for initializing the seed of the
                % winner ensuring a somewhat stochastic process but with
                % reproducable results.
                rng(obj.Channel.Seed);
                obj.WconfigParset{model}.RandomSeed = randi(999);

            end
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
            % This overwrites the method of the baseclass :class:`ch.SONOHImodels.sonohiBase`.
            % The logic is similar to that of the baseclass, however the loss is computed from the wavefrom on which the impulse response is applied. 
						obj = obj.setup(Stations, Users);
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
                    h = obj.h{model}{link};
                    
                    % Setup tranmission
                    User = obj.setWaveform(Station, User);

                    % Get corresponding TxSig
                    [lossdB, User] = obj.applyWINNER(User, h, obj.Channel.enableFading);
                    User = obj.calculateRecievedPower(Station, User, lossdB);

                    %plot(10*log10(abs(fftshift(fft(rxSig)).^2)));
                    %plot(10*log10(abs(fftshift(fft(rxSig2{1}))).^2));

                    % Normalize signal and add loss as AWGN based on
                    % noise floor
                    User = obj.addAWGN(Station, User);

                    User = obj.addPropDelay(Station, User);

                    users([Users.NCellID] == UserId) = User;
                end
            end
        end

        function rx = applyWINNERimpluse(obj, tx,h)
            % Applies the impulse response by the use of fft
            H = fft(h,length(tx));
            % Apply transfer function to signal
            X = fft(tx)./length(tx);
            Y = X.*H;
            rx = ifft(Y)*length(tx);
        end

   
        function [RxNode] = calculateRecievedPower(obj, TxNode, RxNode, lossdB)
            % Given the loss of the impulse response and the EIRP of the transmitter, the recieved power is computed.
            EIRPdBm = TxNode.Tx.getEIRPdBm; % 
            rxPwdBm = EIRPdBm-lossdB-RxNode.Rx.NoiseFigure; %dBm
            RxNode.Rx.RxPwdBm = rxPwdBm;
    
        end

        function [lossdB, RxNode] = applyWINNER(obj, RxNode, h, enableFading)
            % Applies WINNER model, e.g. applies the computed impulse response. If fading is enabled the resulting waveform is normalized and the power difference is equal to the combined loss of the channel.
            
            rxSig_ = [RxNode.Rx.Waveform;zeros(25,1)];
            % Local variable used for computing difference in power
            rxSigPw_ = sum(rxSig_.*conj(rxSig_));

            % apply WINNER impulse response
            rxSig_ = obj.applyWINNERimpluse(rxSig_, h);
            rxPw_ = sum(rxSig_.*conj(rxSig_));
            lossdB = 10*log10(rxSigPw_/rxPw_);
            
            if enableFading
                % Normalize the signal
                rxSigNorm = rxSig_.*10^(lossdB/10); 
                RxNode.Rx.Waveform = rxSigNorm;
            end
            
        end
    end
    
    methods(Static)

        function [AA, eNBIdx, userIdx] = configureAA(type,stations,users)
            % Configures the antenna arrays and their radiation patterns
            % For macro stations a ULA Antenna array with 12 elements are considered.
            % For micro stations a ULA Antenna array with 6 elements are considered.
            % For UEs, a ULA antenna array with 1 element is considered.
            % Number of sectors are per default defined to be zero, thus the antenna is omnidirectional.
            if strcmp(type,'macro')
                if ~exist('macroAA.mat')
                  Az = -180:179;
                  pattern(1,:,1,:) = winner2.dipole(Az,10);
                  AA(1) = winner2.AntennaArray('ULA', 12, 0.15,'FP-ECS', pattern, 'Azimuth', Az);
                  save('macroAA.mat','AA')
                else
                  sonohilog('Loading pregenerated antenna AA.','NFO0')
                  load('macroAA.mat');
                end
                %AA(1) = winner2.AntennaArray('UCA', 8,  0.2);
            elseif strcmp(type,'micro')
              if ~exist('microAA.mat')
                Az = -180:179;
                pattern(1,:,1,:) = winner2.dipole(Az,10);
                AA(1) = winner2.AntennaArray('ULA', 6, 0.15,'FP-ECS', pattern,'Azimuth', Az);
                save('microAA.mat','AA')
              else
                sonohilog('Loading pregenerated antenna AA.','NFO0')
                load('microAA.mat');
              end
                %AA(1) = winner2.AntennaArray('UCA', 4,  0.15);
            else

                sonohilog(sprintf('Antenna type for %s BsClass not defined, defaulting.',type),'WRN')
                AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
            end

            % User antenna array

            if ~exist('UEAA.mat')
              ueAA = winner2.AntennaArray('ULA', 1,  0.05);
              save('UEAA.mat','ueAA')
              AA(2) = ueAA;
            else
              sonohilog('Loading pregenerated antenna AA.','NFO0')
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

        function cfgLayout =initializeLayout(useridx, eNBidx, numLinks, AA)
            % Initialize layout struct by antenna array and number of
            % links.
            cfgLayout = winner2.layoutparset(useridx, eNBidx, numLinks, AA);

        end

        function cfgLayout = addAssociated(cfgLayout, stations, users)
            % Adds the index of the stations and users associated, e.g.
            % how they link with the station and user objects.
            cfgLayout.StationIdx = stations;
            cfgLayout.UserIdx = users;

        end


        function cfgLayout = setPositions(cfgLayout, Stations, Users)
            % Set the position of the base station and the users in the WINNER layout struct.
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
            % Change useridx of pairing to reflect WINNER structure
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
            % Setting of propagation scenario based on the station type and region selected.
            % A list of 
            numLinks = length(cfgLayout.Pairing(1,:));

            for i = 1:numLinks
                userIdx = cfgLayout.UserIdx(cfgLayout.Pairing(2,i)-max(cfgLayout.Pairing(1,:)));
                stationNCellId =  cfgLayout.StationIdx(cfgLayout.Pairing(1,i));
                cBs = Stations([Stations.NCellID] == stationNCellId);
                cMs = Users([Users.NCellID] == userIdx);
                % Apparently WINNERchan doesn't compute distance based
                % on height, only on x,y distance. Also they can't be
                % doubles.
                distance = Ch.getDistance(cBs.Position(1:2),cMs.Position(1:2));
                if distance >= 5000
                    % Winner only supports < 5km
                    sonohilog('Distance is above 5km, not supported for the WINNER channel model','ERR')
                end
                LOS = Ch.isLinkLOS(cBs, cMs, false);
                if cBs.BsClass == 'micro'
                    scenario = str2num(Ch.Region.microScenario);
                    if distance <= 20 && scenario == 3
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B1 with LOS, swapping to B4 LOS', stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');

                        cfgLayout.ScenarioVector(i) = 6; % 
                        cfgLayout.PropagConditionVector(i) = 1; %1 for LOS

                    elseif distance <= 50 && scenario == 3 && ~LOS
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B1 with NLOS, swapping to B1 LOS', stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');

                        cfgLayout.ScenarioVector(i) = 3; % 
                        cfgLayout.PropagConditionVector(i) = 1; %1 for LOS
                    else
                        cfgLayout.ScenarioVector(i) = scenario; % 
                        cfgLayout.PropagConditionVector(i) = LOS; %
                    end
                elseif cBs.BsClass == 'macro'
                    scenario = str2num(Ch.Region.macroScenario);
                    if distance < 50 && scenario == 11 && ~LOS
                        msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for C2 NLOS, swapping to LOS', stationNCellId,userIdx,num2str(distance));
                        sonohilog(msg,'NFO0');
                        cfgLayout.ScenarioVector(i) = 11; %
                        cfgLayout.PropagConditionVector(i) = 1; %
                    else
                        cfgLayout.ScenarioVector(i) = scenario; % C2 Typical urban macro-cell
                        cfgLayout.PropagConditionVector(i) = LOS; %0 for NLOS
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
            maxMSVelocity = max(cell2mat(cellfun(@(x) norm(x, 'fro'), {cfgLayout.Stations.Velocity}, 'UniformOutput', false)));


            cfgModel = winner2.wimparset;
            cfgModel.CenterFrequency = cf*10e5; % Given in Hz
            cfgModel.NumTimeSamples     = frmLen; % Frame length
            cfgModel.IntraClusterDsUsed = 'yes';   % No cluster splitting
            cfgModel.SampleDensity      = max(swSamplingRate)/50;    % To match sampling rate of signal
            cfgModel.PathLossModelUsed  = 'yes';  % Turn on path loss
            cfgModel.ShadowingModelUsed = 'yes';  % Turn on shadowing
            cfgModel.SampleDensity = round(physconst('LightSpeed')/cfgModel.CenterFrequency/2/(maxMSVelocity/max(swSamplingRate)));

        end
        



    end

end