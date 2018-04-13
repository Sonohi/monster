classdef sonohiTemplate

    properties
        Channel;
        Chtype; %Downlink or Uplink
    end

    methods

        function obj = sonohiTemplate(Stations, Users, Channel, Chtype)
            sonohilog('Initializing channel model...','NFO0')
            obj.Channel = Channel;
            obj.Chtype = Chtype;

        end

        function obj = setup(obj)

        end
        

        function [stations,users] = run(obj,Stations,Users, varargin)

        switch obj.Chtype
            case 'downlink'
                users = obj.downlink(Stations,Users);
                stations = Stations;
            case 'uplink'
                stations = obj.uplink(Stations,Users);
                users = Users;
        end

        end

    
    end
    

    methods (Access=private) 

        function [users] = downlink(obj,Stations,Users)
            users = Users;
            numLinks = length(Users);
            Pairing = obj.Channel.getPairing(Stations);
            % Get links, for each link
            for i = 1:numLinks
                % Local copies for mutation 
                station = Stations([Stations.NCellID] == Pairing(1,i));
                user = Users(find([Users.NCellID] == Pairing(2,i))); %#ok

                % compute link budget (do pathloss computation)
                user = obj.computeLinkBudget(station, user);
                if strcmp(obj.Channel.fieldType,'full')
                    user = obj.addFading(station, user);
                    user = obj.addNoise(station, user);
                else
                    user = obj.addNoise(station, user);
                end
                
                user = obj.addPropDelay(station, user);

                % Write changes to user object in array.
                users(find([Users.NCellID] == Pairing(2,i))) = user;
            end


        end

        function [stations] = uplink(obj,Stations,Users)
            % Update the Rx module of stations
        end

        function RxNode = addPropDelay(obj,  TxNode, RxNode)
            RxNode.Rx.PropDelay = obj.Channel.getDistance(TxNode.Position, RxNode.Position);
        end

        function [RxNode] = addNoise(obj, TxNode, RxNode)
            rxNoiseFloor = 10*log10(obj.Channel.ThermalNoise(Station.NDLRB));
            SNR = rxPwdBm-rxNoiseFloor;
            SNRLin = 10^(SNR/10);
            str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n RxPw:  %s\n',...
                Station.NCellID,User.NCellID,num2str(distance),num2str(SNR),num2str(rxPwdBm));
            sonohilog(str1,'NFO0');
            Es = sqrt(2.0*TxNode.CellRefP*double(TxNode.Tx.WaveformInfo.Nfft) * ...
				TxNode.Tx.WaveformInfo.OfdmEnergyScale);

            % Compute spectral noise density NO
            N0 = 1/(Es*SNRLin);

            % Add AWGN
            noise = N0*complex(randn(size(txSig)), ...
                randn(size(txSig)));

            rxSig = txSig + noise;

            RxNode.Rx.SNR = SNRLin;
            RxNode.Rx.Waveform = rxSig;

        end

        function [RxNode] = computeLinkBudget(obj, TxNode, RxNode)
            % Compute link budget for tx->rx
            % returns updated RxPwdBm of RxNode.Rx
            lossdB = obj.computePathLoss(TxNode, RxNode);
            txPw = 10*log10(TxNode.getTransmissionPower)+30;
            rxPwdBm = txPw-lossdB-RxNode.Rx.NoiseFigure; %dBm
            RxNode.Rx.RxPwdBm = rxPwdBm;

        end

        function [lossdB] = computePathLoss(obj, TxNode, RxNode)
            f = TxNode.Frequency; % Frequency in MHz
            percentage_time = 50; % Percentage time 
            tx_heff = TxNode.Position(3); % Effective height of transmitter
            rx_heff = RxNode.Position(3); % Height of receiver

            areatype = obj.Channel.Region; % 'Rural', 'Urban', 'Dense Urban', 'Sea'


            % R2: Representative clutter height around receiver 
            % Typical values: 
            % R2=10 for area='Rural' or 'Suburban' or 'Sea'
            % R2=20 for area='Urban'
            % R2=30 for area='Dense Urban'
            if strcmp(areatype,'Rural') || strcmp(areatype,'Suburban') || strcmp(areatype,'Sea')
                R2 = 10;
            elseif strcmp(areatype,'Urban')
                R2 = 20;
            else
                R2 = 30;
            end
        
            distance = obj.Channel.getDistance(hbPos,hmPos)/1e3; % in Km.

            % Cell of strings defining the path        'Land', 'Sea',
            % zone for each given path length in d_v   'Warm', 'Cold'
            % starting from transmitter/base terminal
            path_c = 'Land'; 

            % TODO: add terrain profile info from building grid
            % 0 - no terrain profile information available, 
            % 1 - terrain information available
            pathinfo = 0; 


            [~,lossdB] = P1546FieldStrMixed(f,percentage_time,tx_heff,rx_heff,R2,areatype,distance,path_c, pathinfo);
        end


        function RxNode = addFading(obj, TxNode, RxNode)
            cfg.SamplingRate = TxNode.WaveformInfo.SamplingRate;
            cfg.Seed = RxNode.Seed;        % Rx specific seed
            cfg.NRxAnts = 1;               % 1 receive antenna
            cfg.DelayProfile = 'EPA';      % EVA delay spread
            cfg.DopplerFreq = 5;         % 120Hz Doppler frequency
            cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
            cfg.InitTime = obj.Channel.SimTime;  % Initialization relative to sim time
            cfg.NTerms = 16;               % Oscillators used in fading model
            cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
            cfg.InitPhase = 'Random';      % Random initial phases
            cfg.NormalizePathGains = 'On'; % Normalize delay profile power
            cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas
            % Pass data through the fading channel model
            sig = [TxNode.Tx.Waveform;zeros(25,1)]; 
            rxsig = lteFadingChannel(cfg,sig);
            RxNode.Rx.Waveform = rxsig;
        end

    end

end
