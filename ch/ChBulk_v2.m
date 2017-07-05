classdef ChBulk_v2
    %CHBULK_V2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Area;
        Mode;
        Buildings;
        Draw;
        Region;
        WconfigLayout;
        WconfigParset;
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
        
       function [numPoints,dist_vec,elavation_profile] = getElavation(obj,tx_pos,rx_pos)
            
            elavation_profile(1) = 0;
            dist_vec(1) = 0;
            % Walk towards rx_pos
            sign_x = sign(rx_pos(1)-tx_pos(1));
            sign_y = sign(rx_pos(2)-tx_pos(2));
            avg_g = (tx_pos(1)-rx_pos(1))/(tx_pos(2)-rx_pos(2));
            position(1:2,1) = tx_pos(1:2);
            %plot(position(1,1),position(2,1),'r<')
            i = 2;
            numPoints = 0;
            while true
                % Check current distance
                distance = norm(position(1:2,i-1)'-rx_pos(1:2));
                              
                % Move position
                [moved_dist,position(1:2,i)] = move(position(1:2,i-1),sign_x,sign_y,avg_g,0.1);
                dist_vec(i) = dist_vec(i-1)+moved_dist;
                %plot(position(1,i),position(2,i),'bo')
                % Check if new position is at a greater distance, if so, we
                % passed it.
                distance_n = norm(position(1:2,i)'-rx_pos(1:2));
                if distance_n > distance
                   break; 
                else
                    % Check if we're inside a building
                    fbuildings_x = obj.Buildings(obj.Buildings(:,1) < position(1,i) & obj.Buildings(:,3) > position(1,i),:);
                    fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);
                    
                    if ~isempty(fbuildings_y)
                       elavation_profile(i) = fbuildings_y(5);
                       if elavation_profile(i-1) == 0
                          numPoints = numPoints +1; 
                       end
                    else
                       elavation_profile(i) = 0;
                        
                    end
                end
                i = i+1;
            end
            
            %figure
            %plot(elavation_profile)
            
            
           function [distance,position] = move(position,sign_x,sign_y,avg_g,move_s)
               if abs(avg_g) > 1
                    move_x = abs(avg_g)*sign_x*move_s;
                    move_y = 1*sign_y*move_s;
                    position(1) = position(1)+move_x;
                    position(2) = position(2)+move_y;
                    
               else
                   move_x = 1*sign_x*move_s;
                   move_y = (1/abs(avg_g))*sign_y*move_s;
                   position(1) = position(1)+move_x;
                   position(2) = position(2)+move_y;
               end
               distance = sqrt(move_x^2+move_y^2);
           end
            
        end
        
        function rxSig = add_pathloss_awgn(obj,Station,User,txSig,varargin)
            thermalNoise = obj.ThermalNoise(Station.NDLRB);
            hbPos = Station.Position;
            hmPos = User.Position;
            distance = obj.getDistance(hbPos,hmPos)/1e3;
            switch obj.Mode
                case 'eHATA'
                    %[lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.Freq, ...
                     %   distance, hb_pos(3), hm_pos(3), obj.Region);
                    
                    [numPoints,dist_vec,elev_profile] = obj.getElavation(hbPos,hmPos);
                    
                    if numPoints == 0
                        numPoints_scale = 1;
                    else
                        numPoints_scale = numPoints;
                    end
                    
                    elev = [numPoints_scale; dist_vec(end)/(numPoints_scale); hbPos(3); elev_profile'; hmPos(3)];

                     lossdB = ExtendedHata_PropLoss(Station.Freq, hbPos(3), ...
                         hmPos(3), obj.Region, elev);
                     
                case 'winner'
                    
                    

                    
            end
            
            % TODO; make sure this is scaled based on active
            % subcarriers.
            % Link budget
            txPw = 10*log10(Station.Pmax)+30; %dBm.
            
            rxPw = txPw-lossdB;
            % SNR = P_rx_db - P_noise_db
            rxNoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
            SNR = rxPw-rxNoiseFloor;
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
            
            noise = N0*complex(randn(size(txSig)), ...
                randn(size(txSig)));
            
            rxSig = txSig + noise;
            
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
        
        function [cfgLayout,cfgModel] = configure_winner(obj,Stations,Users)
            sonohilog('Setting up WINNER II channel model...','NFO')
            
            % Find number of base station types
            % A model is created for each type
            classes = unique({Stations.BsClass});
            for class = 1:length(classes)
                varname = classes{class};    
                types.(varname) = find(strcmp({Stations.BsClass},varname));
            
            end
            
            Snames = fieldnames(types);
            
            for model = 1:numel(Snames)
                type = Snames{model};
                stations = types.(Snames{model});
                
                
                % Get number of links associated with the station.
                users = nonzeros([Stations(stations).Users]);
                numLinks = nnz(users);
                
                if isempty(users)
                   % If no users are associated, skip the model
                   continue 
                end
                
                % Select antenna array based on station class.
                if strcmp(type,'macro')
                    AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
                elseif strcmp(type,'micro')
                    AA(1) = winner2.AntennaArray('UCA', 1,  0.15);
                else
                    
                    sonohilog(sprintf('Antenna type for %s BsClass not defined, defaulting...',type),'WRN')
                    AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
                end
                
                % User antenna array
                AA(2) = winner2.AntennaArray('UCA', 1,  0.05);
                
                % Assign AA(1) to all stations
                eNBidx = num2cell(ones(length(stations),1));
                
                % For users use antenna configuration 2
                useridx = repmat(2,1,length(users));
                
                range = max(obj.Area);
                
                cfgLayout{model} = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);
                
                % Add station idx and user idx
                cfgLayout{model}.Station_idx = stations;
                cfgLayout{model}.User_idx = users;
                
                % Set the position of the base station
                for iStation = 1:length(stations)
                    cfgLayout{model}.Stations(iStation).Pos(1:2) = Stations(stations(iStation)).Position(1:2);
                end
                
                % Set the position of the users
                for iUser = 1:length(users)
                    cfgLayout{model}.Stations(iUser+length(stations)).Pos(1:2) = Users(users(iUser)).Position(1:2);
                end
                
                cfgLayout{model}.Pairing = obj.getPairing(Stations(stations));
                
                % Change useridx of pairing to reflect
                % cfgLayout.Stations, e.g. user one is most likely
                % cfgLayout.Stations(2)
                for ll = 1:length(cfgLayout{model}.Pairing(2,:))
                   cfgLayout{model}.Pairing(2,ll) =  length(stations)+ll;
                    
                end
                
                
                for i = 1:numLinks
                    
                    c_bs = Stations(cfgLayout{model}.Pairing(1,i));
                    c_ms = Users(cfgLayout{model}.Pairing(2,i)-length(stations));
                    if c_bs.BsClass == 'micro'
                        cfgLayout{model}.ScenarioVector(i) = 6; % B4 Typical urban micro-cell
                        cfgLayout{model}.PropagConditionVector(i) = 0; %0 for NLOS
                    else
                        if obj.getDistance(c_bs.Position,c_ms.Position) < 50
                            sonohilog(sprintf('Distance is %s, which is less than supported for C2, swapping to B5d',num2str(obj.getDistance(c_bs.Position,c_ms.Position))),'NFO')
                            cfgLayout{model}.ScenarioVector(i) = 11; % B5d NLOS hotspot metropol
                            cfgLayout{model}.PropagConditionVector(i) = 1; %1 for LOS
                        else
                            cfgLayout{model}.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
                            cfgLayout{model}.PropagConditionVector(i) = 0; %0 for NLOS
                        end
                    end
                    
                    
                end
                
                %numBSSect = sum(cfgLayout{model}.NofSect);
                %numMS = length(users);
                
                % Get all BS sector and MS positions
                %BSPos = cell2mat({cfgLayout{model}.Stations(1:numBSSect).Pos});
                %MSPos = cell2mat({cfgLayout{model}.Stations(numBSSect+1:end).Pos});

 
                %hold on
                %for linkIdx = 1:numLinks  % Plot links
                %    pairStn = cfgLayout{model}.Pairing(:,linkIdx);
                %    pairPos = cell2mat({cfgLayout{model}.Stations(pairStn).Pos});
                %    if obj.Draw
                %       
                %        plot(pairPos(1,:), pairPos(2,:),'LineWidth',1,'Color',[0,0,0.7,0.3]);
                %        
                %    end
                %end
                
                % Use maximum fft size
                % However since the same BsClass is used these are most
                % likely to be identical
                sw = [Stations(stations).WaveformInfo];
                sw_nfft = [sw.Nfft];
                sw_SamplingRate = [sw.SamplingRate];
                cf = max([Stations(stations).Freq]); % Given in MHz

                frmLen = double(max(sw_nfft))*4;   % Frame length

                % Configure model parameters
                cfgModel{model} = winner2.wimparset;
                cfgModel{model}.NumTimeSamples     = frmLen; % Frame length
                cfgModel{model}.IntraClusterDsUsed = 'yes';   % No cluster splitting
                cfgModel{model}.SampleDensity      = sw_SamplingRate/50;    % To match sampling rate of signal
                cfgModel{model}.PathLossModelUsed  = 'yes';  % Turn on path loss
                cfgModel{model}.ShadowingModelUsed = 'yes';  % Turn on shadowing
                cfgModel{model}.CenterFrequency = cf*10e6; % Given in Hz   
                
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
            
            % Assuming one antenna port, number of links are equal to
            % number of users scheuled in the given round
            users  = [Stations.Users];
            numLinks = nnz(users);
            
            Pairing = obj.getPairing(Stations);
            % Apply channel based on configuration.
            if strcmp(obj.Mode,'winner')
                [obj.WconfigLayout, obj.WconfigParset] = obj.configure_winner(Stations,Users);
                
                % Compute Rx for each model
                for model = 1:length(obj.WconfigLayout)
                    
                    if isempty(obj.WconfigLayout{model})
                        sonohilog(sprintf('Nothing assigned to %i model',model),'NFO')
                        continue
                    end
                    
                    wimCh = comm.WINNER2Channel(obj.WconfigParset{model}, obj.WconfigLayout{model});
                    
                    chanInfo = info(wimCh);
                    numTx    = chanInfo.NumBSElements(1);
                    Rs       = chanInfo.SampleRate(1);
                    
                   SA = dsp.SpectrumAnalyzer( ...
                    'SampleRate',   Rs, ...
                    'ShowLegend',   true, ...
                    'ChannelNames', {'MS 1 (8 meters away)'});
                
                
                
                   impulse_r = [ones(1, numTx); zeros(obj.WconfigParset{model}.NumTimeSamples-1, numTx)];
                   h = wimCh(impulse_r);

                    h_1 = h{1}(:,1);



                     SA(h_1)
                

                    stations = obj.WconfigLayout{model}.Station_idx;
                    users = obj.WconfigLayout{model}.User_idx;
                    
                    
                    
                end
                
                
                
            elseif strcmp(obj.Mode,'eHATA')            
                for i = 1:numLinks
                    station = Stations(Pairing(1,i));           
                    Users(Pairing(2,i)).RxWaveform = obj.add_fading([station.TxWaveform;zeros(25,1)],station.WaveformInfo);
                    Users(Pairing(2,i)).RxWaveform = obj.add_pathloss_awgn(station,Users(Pairing(2,i)),Users(Pairing(2,i)).RxWaveform);

                end
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

