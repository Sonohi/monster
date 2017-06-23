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
        
        function rxSig = add_pathloss_awgn(obj,Station,User)
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
            SNR = rxPw-10*log10(thermalNoise);
            SNR_lin = 10^(SNR/10);
            str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
                Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
            sonohilog(str1,'NFO0');
            
            %% Apply SNR
            tx_sig = Station.TxWaveform;
            % Compute average symbol energy og signal (E_s)
            E_s = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft));
            
            % Compute spectral noise density NO
            N0 = 1/(E_s*SNR_lin);
            
            % Add AWGN
            
            noise = N0*complex(randn(size(tx_sig)), ...
                randn(size(tx_sig)));
            
            rxSig = tx_sig + noise;
            
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
            
            freq_MHz = 1900;
            region =  'DenseUrban';
            
            
            nlink=1;
            for i = 1:length(Stations)
                for ii = 1:nnz(users(:,i))
                    Pairing(:,nlink) = [i; users(ii,i)];
                    nlink = nlink+1;
                end
            end
            
            % Traverse for all inks.
            
            for i = 1:numLinks
                idxStation = Pairing(1,i);
                idxUser = Pairing(2,i);
                Users(idxUser).RxWaveform = obj.add_pathloss_awgn(Stations(idxStation),Users(idxUser));
                
            end
           
        end
    end
end

