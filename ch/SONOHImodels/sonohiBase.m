classdef sonohiBase

    properties
        Channel;
        Seed;
        Chtype; %Downlink or Uplink
    end

    methods

        function obj = sonohiBase(Channel, Chtype)
            sonohilog('Initializing channel model...','NFO0')
            obj.Channel = Channel;
            obj.Seed = randi(99999);
            obj.Chtype = Chtype;

        end

        function [stations,users] = run(obj,Stations,Users,varargin)

            if ~isempty(varargin)
                vargs = varargin;
                nVargs = length(vargs);
                
                for k = 1:nVargs
                    if strcmp(vargs{k},'channel')
                        obj.Channel = vargs{k+1};
                    end
                end
            end


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
        % TODO this can quite easily be generalized to uplink
        function [users] = downlink(obj,Stations,Users)
            users = Users;
            numLinks = length(Users);
            Pairing = obj.Channel.getPairing(Stations);
            for i = 1:numLinks
                % Local copy for mutation
                station = Stations([Stations.NCellID] == Pairing(1,i));
                user = Users(find([Users.NCellID] == Pairing(2,i))); %#ok
                
                % Setup transmission
                user = obj.setWaveform(station, user);
                
                % compute link budget and calculate Receiver power
                user = obj.computeLinkBudget(station, user);

                if strcmp(obj.Channel.fieldType,'full')
                if obj.Channel.enableFading
                    user = obj.addFading(user);
                end
                user = obj.addAWGN(station, user);
                else
                user = obj.addAWGN(station, user);
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


    function RxNode = setWaveform(~, TxNode, RxNode)
        % Enables transmission, all impairments are added on Rx.Waveform
        RxNode.Rx.Waveform = TxNode.Tx.Waveform;
        RxNode.Rx.WaveformInfo =  TxNode.Tx.WaveformInfo;
    end

    function [RxNode] = computeLinkBudget(obj, TxNode, RxNode)
        % Compute link budget for tx->rx
        % returns updated RxPwdBm of RxNode.Rx
        lossdB = obj.computePathLoss(TxNode, RxNode);
        EIRPdBm = 10*log10(TxNode.Tx.getEIRPSymbol)+30; % Convert EIRP per symbol in watts to dBm
        rxPwdBm = EIRPdBm-lossdB-RxNode.Rx.NoiseFigure; %dBm
        RxNode.Rx.RxPwdBm = rxPwdBm;

    end

    function RxNode = addFading(obj, RxNode)
        cfg.SamplingRate = RxNode.Rx.WaveformInfo.SamplingRate;
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
        sig = [RxNode.Rx.Waveform;zeros(25,1)]; 
        rxsig = lteFadingChannel(cfg,sig);
        RxNode.Rx.Waveform = rxsig;
    end

    function [RxNode] = addAWGN(obj, TxNode, RxNode)
      % Function adds combined noise using the calculated link budget
  
        rxNoiseFloor = 10*log10(obj.Channel.ThermalNoise(TxNode.NDLRB));
        SNR = RxNode.Rx.RxPwdBm-rxNoiseFloor;
        SNRLin = 10^(SNR/10);
        str1 = sprintf('Station(%i) to User(%i)\n SNR:  %s\n RxPw:  %s\n',...
            TxNode.NCellID,RxNode.NCellID,num2str(SNR),num2str(RxNode.Rx.RxPwdBm));
        sonohilog(str1,'NFO0');
        Es = sqrt(2.0*TxNode.CellRefP*double(RxNode.Rx.WaveformInfo.Nfft) * ...
                  RxNode.Rx.WaveformInfo.OfdmEnergyScale);

        % Compute spectral noise density NO
        N0 = 1/(Es*SNRLin);

        % Add AWGN
        noise = N0*complex(randn(size(RxNode.Rx.Waveform)), ...
            randn(size(RxNode.Rx.Waveform)));

        rxSig = RxNode.Rx.Waveform + noise;

        RxNode.Rx.SNR = SNRLin;
        RxNode.Rx.Waveform = rxSig;

    end

    end

end
