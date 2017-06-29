classdef ChBulk_v2
    %CHBULK_V2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Area;
        Mode;
        Buildings;
        Draw;
        Region;
    end
    
    methods(Static)
        
        
        function distance = getDistance(tx_pos,rx_pos)
            distance = norm(rx_pos-tx_pos);
        end
        
        function thermalNoise = ThermalNoise(NDLRB)
            switch NDLRB
                case 6
                    BW = 1.4e6;
                case 15
                    BW = 3e6;
                case 25
                    BW = 5e6;
                case 50
                    BW = 10e6;
                case 75
                    BW = 15e6;
                case 100
                    BW = 20e6;
            end
            
            T = 290;
            k = physconst('Boltzmann');
            thermalNoise = k*T*BW;
        end
        
        
        
        
    end
    
    methods(Access = private)
        
        function rxSig = add_pathloss_awgn(obj,Station,User,tx_sig)
            thermalNoise = obj.ThermalNoise(Station.NDLRB);
            hb_pos = Station.Position;
            hm_pos = User.Position;
            distance = obj.getDistance(hb_pos,hm_pos)/1e3;
            switch obj.Mode
                case 'eHATA'
                    [lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.Freq, ...
                        distance, hb_pos(3), hm_pos(3), obj.Region);
                    
            end
            
            % TODO; make sure this is scaled based on active
            % subcarriers.
            % Link budget
            txPw = 10*log10(Station.Pmax)+30; %dBm.
            
            rxPw = txPw-lossdB;
            % SNR = P_rx_db - P_noise_db
            rx_NoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
            SNR = rxPw-rx_NoiseFloor;
            SNR_lin = 10^(SNR/10);
            str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
                Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
            sonohilog(str1,'NFO0');
            
            %% Apply SNR
 
            % Compute average symbol energy 
            % This is based on the number of useed subcarriers.
            % Scale it by the number of used RE since the power is
            % equally distributed
            E_s = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft)*Station.WaveformInfo.OfdmEnergyScale);
         
            % Compute spectral noise density NO
            N0 = 1/(E_s*SNR_lin);
            
            % Add AWGN
            
            noise = N0*complex(randn(size(tx_sig)), ...
                randn(size(tx_sig)));
            
            rxSig = tx_sig + noise;
            
        end
        
        function rx = add_fading(obj,tx,info)
            cfg.SamplingRate = info.SamplingRate;
            cfg.Seed = 1;                  % Random channel seed
            cfg.NRxAnts = 1;               % 1 receive antenna
            cfg.DelayProfile = 'EVA';      % EVA delay spread
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
        
        function H_ch = configure_fading(obj,Stations,Users)
            disp('Setting up WINNER II channel model...')
            % Construct anteanna array, eNB and users
            AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
            AA(2) = winner2.AntennaArray('UCA', 1,  0.05);
            
            % Use antenna config 1, and establish three sectors pr basestation
            %eNBidx = {[1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]};
            eNBidx = num2cell(ones(length(Stations),1));
            %eNBidx = {repmat([ones(1,3)],length(Stations),1)};
            % For users use antenna configuration 2
            useridx = repmat(2,1,length(Users));
            
            range = max(obj.Area);
            % Assuming one antenna port, number of links are equal to
            % number of users scheuled in the given round
            users  = [Stations.Users];
            numLinks = nnz(users);
            
            cfgLayout = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);
            
            
            % Stations are given as 1:6 and users are given as
            % 7:21 as seen in cfgLayout.Stations. Pairs are given
            % by association determined at the scheduling round,
            % thus paring should be [i;
            % Station(i).Schedule(iRound).ueId+length(Stations)]
            
            for i = 1:length(Stations)
                cfgLayout.Stations(i).Pos(1:2) = Stations(i).Position(1:2);
                
            end
            
            for ii = 1:length(Users)
                cfgLayout.Stations(ii+length(Stations)).Pos(1:2) = Users(ii).Position(1:2);
            end
            
            % Each link is assigned with one propagation scenario,
            % chosen from B4 (outdoor to indoor), C2 (Urban macro-cell)
            % and C4 (Urban macro outdoor to indoor). Non-line-of-sight
            % (NLOS) is modelled for each link.
            
            % For each station create pairing based on associated
            % users.
            nlink=1;
            for i = 1:length(Stations)
                for ii = 1:nnz(users(:,i))
                    cfgLayout.Pairing(:,nlink) = [i; users(ii,i)+length(Stations)];
                    nlink = nlink+1;
                end
            end
            
            
            % Loop through pairings and set Scenarios based on
            % station type
            
            for i = 1:numLinks
                
                c_bs = Stations(cfgLayout.Pairing(1,i));
                c_ms = Users(cfgLayout.Pairing(2,i)-length(Stations));
                if c_bs.BsClass == 'micro'
                    cfgLayout.ScenarioVector(i) = 6; % B4 Typical urban micro-cell
                    cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                else
                    if obj.getDistance(c_bs.Position,c_ms.Position) < 50
                        cfgLayout.ScenarioVector(i) = 6; % B5d NLOS hotspot metropol
                        cfgLayout.PropagConditionVector(i) = 1; %1 for LOS
                    else
                        cfgLayout.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
                        cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                    end
                end
                
                
            end
            
            
            numBSSect = sum(cfgLayout.NofSect);
            numMS = length(useridx);
            
            % Get all BS sector and MS positions
            BSPos = cell2mat({cfgLayout.Stations(1:numBSSect).Pos});
            MSPos = cell2mat({cfgLayout.Stations(numBSSect+1:end).Pos});
            
            
            for linkIdx = 1:numLinks  % Plot links
                pairStn = cfgLayout.Pairing(:,linkIdx);
                pairPos = cell2mat({cfgLayout.Stations(pairStn).Pos});
                if obj.Draw
                    plot(pairPos(1,:), pairPos(2,:),'LineWidth',1,'Color',[0,0,0.7,0.3]);
                end
            end
            
            
        end
        
        
    end
    
    methods
        function obj = ChBulk_v2(Param)
            obj.Area = Param.area;
            obj.Mode = Param.channel.mode;
            obj.Buildings = Param.buildings;
            obj.Draw = Param.draw;
            obj.Region = Param.channel.region;
        end
        
        
        
        function [Stations,Users,obj] = traverse(obj,Stations,Users)
            eNBpos = cell2mat({Stations(:).Position}');
            userpos = cell2mat({Users(:).Position}');
            
            % Assume a single link per stations
            numLinks = length(Stations);
            
            % Assuming one antenna port, number of links are equal to
            % number of users scheuled in the given round
            users  = [Stations.Users];
            numLinks = nnz(users);
            
            Pairing = obj.getPairing(Stations);
            

            
            
            %fading_channel = obj.configure_fading(Stations,Users);
            % Traverse for all links.
            
            for i = 1:numLinks
                station = Stations(Pairing(1,i));
                user = Users(Pairing(2,i));
                Users(Pairing(2,i)).RxWaveform = obj.add_fading([station.TxWaveform;zeros(25,1)],station.WaveformInfo);
                Users(Pairing(2,i)).RxWaveform = obj.add_pathloss_awgn(station,Users(Pairing(2,i)),Users(Pairing(2,i)).RxWaveform);
                %Users(Pairing(2,i)).RxWaveform = obj.add_pathloss_awgn(station,Users(Pairing(2,i)),station.TxWaveform);
                
            end
            
        end
        
        function Pairing = getPairing(obj,Stations)
            users  = [Stations.Users];

            nlink=1;
            for i = 1:length(Stations)
                for ii = 1:nnz(users(:,i))
                    Pairing(:,nlink) = [i; users(ii,i)];
                    nlink = nlink+1;
                end
            end
           
        end
    end
end

