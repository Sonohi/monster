classdef ChBulk_v1 < handle
    properties (Access = private)
        c = physconst('lightspeed');
    end
    
    properties
        User;
        InitTime;
        Seed;
        Mode;
        Tx_pos;
        SamplingRate;
        NRxAnts;
        NormalizeTxAnts;
        DelayProfile;
        DopplerFreq;
        MIMOCorrelation;
        NTerms;
        ModelType;
        InitPhase;
        Random;
        NormalizePathGains;
        MovingScenario;
        CarrierFrequency;
    end
    
    
    methods(Static)
        function distance = getDistance(tx_pos,rx_pos)
             distance = norm(rx_pos-tx_pos);
        end    
    
    end

    methods (Access = private)

        function loss = multipath_loss(obj,pos_base,pos_mobile,vel_base,vel_mobile,signal)
            
            distance = obj.getDistance(pos_base,pos_mobile);
            
            tworaychannel = phased.TwoRayChannel('PropagationSpeed',obj.c,...
                                                 'OperatingFrequency',obj.CarrierFrequency);
                                             
            out_s = tworaychannel(signal,pos_base,pos_mobile,vel_base,vel_mobile);

            % Total path loss
            loss = pow2db(bandpower(signal))-pow2db(bandpower(out_s));
        end
        
        function loss = free_space_path_loss(obj,distance)
            % FSPL equation. 
            loss = 20*log10(distance)+20*log10(obj.CarrierFrequency)+20*log10((4*pi)/obj.c);
        end
        
    end
    
    methods
        % Constructor
        function obj = ChBulk_v1(param,station)
            obj.Mode = param.channel.mode;
            obj.Tx_pos = station.Position;
            obj.CarrierFrequency = 1900e6; % Default 1900 MHz
            switch param.channel.mode
                
                % Standard mobility case ref:
                % [https://se.mathworks.com/help/lte/ref/ltemovingchannel.html]
                case 'mobility_matlab'
                    obj.NRxAnts = 1;
                    obj.NormalizeTxAnts = 'On';
                    obj.DelayProfile = 'ETU';
                    obj.DopplerFreq = 70;
                    obj.MIMOCorrelation = 'Low';
                    obj.NTerms = 16;
                    obj.ModelType = 'GMEDS';
                    obj.InitPhase = 'Random';
                    obj.NormalizePathGains = 'On';
                    obj.MovingScenario = 'Scenario1';
                    obj.InitTime = 0;
                
                % Standard fading channel ref:
                % [https://se.mathworks.com/help/lte/ref/ltefadingchannel.html]
                case 'fading_matlab'
                    obj.NRxAnts = 1;
                    obj.DelayProfile = 'EPA';
                    obj.MIMOCorrelation = 'Low';
                    obj.InitPhase = 'Random';
                    obj.ModelType = 'GMEDS';
                    obj.NTerms = 16;
                    obj.NormalizeTxAnts = 'On';
                    obj.NormalizePathGains = 'On';
                    
                case 'macro_METIS'
                 
                    
                case 'micro_METIS'
             

                case 'multipath_matlab'
                    
                    
                
            end
                
                
        end
        
        
        % Function for setting sampling rate (given by OFDM info of eNB)
        function obj = set.SamplingRate(obj,SamplingRate)
            obj.SamplingRate = SamplingRate;
        end
        
        % Function for setting Seed
        function obj = set.Seed(obj,seed)
            obj.Seed = seed;
        end
        
        % Function for setting user id
        function obj = set.User(obj,userID)
            obj.User = userID;
        end
        
        % Function for setting InitTime
        function obj = set.InitTime(obj,InitTime)
            obj.InitTime = InitTime;
        end
        
        
        % Propagate
        function out = propagate(obj,tx,rx)
            warning off MATLAB:structOnObject
            switch obj.Mode
                
                case 'linear'
                    %Tx position
                    tx_height = 5;
                    tx_pos = [obj.Tx_pos,tx_height].';
                    tx_vel = [0;0;0]; % Static velocity
                    
                    %Rx position
                    rx_height = 1.5;
                    rx_pos = [rx.position,rx_height].';
                    rx_vel = [rx.velocity,0,0].'; 
                    
                    %Compute distance between tx and rx
                    distance = obj.getDistance(tx_pos,rx_pos);
                    
                    %Compute FSPL given distance       
                    L_fspl = obj.free_space_path_loss(distance);
                    
                    %Compute multipath loss given positioning and velocity
                    L_mpf = multipath_loss(obj,tx_pos,rx_pos,tx_vel,rx_vel,tx.TxWaveform);
                    
                    P_loss_db = L_fspl+L_mpf;
                    
                    %Compute SNR from loss and add as AWGN
                    %SNR = 10^((SNRdB-enb.PDSCH.Rho)/20);
                    
                    out = tx.TxWaveform;
                    
                
                case 'fading'
                    out = lteFadingChannel(struct(obj),tx.TxWaveform);
                case 'mobility'
                    out = lteMovingChannel(struct(obj),tx.TxWaveform);
                case 'macro_METIS'
                    out = tx.TxWaveform;
                case 'micro_METIS' 
                    out = tx.TxWaveform;
                    
            end
            
        end
        
        
        
    end
        
        
        
        
    
end