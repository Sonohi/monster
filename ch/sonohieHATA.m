classdef sonohieHATA
    
    properties
        Channel;
    end
    
    methods
        
        function obj = sonohieHATA(Channel)
            obj.Channel = Channel;
            
        end
        
        function Users = run(obj,Stations,Users)
            users  = [Stations.Users];
            numLinks = nnz(users);
            
            Pairing = obj.Channel.getPairing(Stations);
            
            for i = 1:numLinks
                station = Stations(Pairing(1,i));
                
                if strcmp(obj.Channel.fieldType,'full')
                    
                    Users(Pairing(2,i)).RxWaveform = obj.addFading([...
                        station.TxWaveform;zeros(25,1)],station.WaveformInfo);
                    
                    
                    
                    %interLossdB = obj.getInterference(Stations,station,Users(Pairing(2,i)));
                    
                    [Users(Pairing(2,i)).RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
                        station,Users(Pairing(2,i)),Users(Pairing(2,i)).RxWaveform);
                    
                elseif strcmp(obj.Channel.fieldType,'pathloss')
                    [Users([Users.UeId] == Pairing(2,i)).RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
                        station,Users([Users.UeId] == Pairing(2,i)),Users([Users.UeId] == Pairing(2,i)).RxWaveform);
                    
                end
                
                Users([Users.UeId] == Pairing(2,i)).RxInfo.SNRdB = 10*log10(SNRLin);
                Users([Users.UeId] == Pairing(2,i)).RxInfo.SNR = SNRLin;
                Users([Users.UeId] == Pairing(2,i)).RxInfo.rxPw = rxPw;
                
            end
            
            
            
        end
        
        function rx = addFading(obj,tx,info,varargin)
            
            
            % TODO, refactorize to seperate classes
            
            cfg.SamplingRate = info.SamplingRate;
            cfg.Seed = 1;                  % Random channel seed
            cfg.NRxAnts = 1;               % 1 receive antenna
            cfg.DelayProfile = 'EPA';      % EVA delay spread
            cfg.DopplerFreq = 120;         % 120Hz Doppler frequency
            cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
            cfg.InitTime = 0;              % Initialize at time zero
            cfg.NTerms = 16;               % Oscillators used in fading model
            cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
            cfg.InitPhase = 'Random';      % Random initial phases
            cfg.NormalizePathGains = 'On'; % Normalize delay profile power
            cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas
            % Pass data through the fading channel model
            rx = lteFadingChannel(cfg,tx);
            
            
        end
        
        function [rxSig, SNRLin, rxPw] = addPathlossAwgn(obj,Station,User,txSig,varargin)
            thermalNoise = obj.Channel.ThermalNoise(Station.NDLRB);
            hbPos = Station.Position;
            hmPos = User.Position;
            distance = obj.Channel.getDistance(hbPos,hmPos)/1e3;
            
            %[lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.DlFreq, ...
            %  distance, hbPos(3), hmPos(3), obj.Region);
            
            [numPoints,distVec,elev_profile] = obj.Channel.getElevation(hbPos,hmPos);
            
            if numPoints == 0
                numPoints_scale = 1;
            else
                numPoints_scale = numPoints;
            end
            
            elev = [numPoints_scale; distVec(end)/(numPoints_scale); hbPos(3); elev_profile'; hmPos(3)];
            
            lossdB = ExtendedHata_PropLoss(Station.DlFreq, hbPos(3), ...
                hmPos(3), obj.Channel.Region, elev);
            
            
            
            
            txPw = 10*log10(Station.Pmax)+30; %dBm.
            
            rxPw = txPw-lossdB;
            % SNR = P_rx_db - P_noise_db
            rxNoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
            SNR = rxPw-rxNoiseFloor;
            SNRLin = 10^(SNR/10);
            str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
                Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
            sonohilog(str1,'NFO0');
            
            %% Apply SNR
            
            % Compute average symbol energy
            % This is based on the number of useed subcarriers.
            % Scale it by the number of used RE since the power is
            % equally distributed
            Es = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft)*Station.WaveformInfo.OfdmEnergyScale);
            
            % Compute spectral noise density NO
            N0 = 1/(Es*SNRLin);
            
            % Add AWGN
            
            noise = N0*complex(randn(size(txSig)), ...
                randn(size(txSig)));
            
            rxSig = txSig + noise;
            
        end
        
        
        
        
        
        
    end
    
    
    
    
    
end