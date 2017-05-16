classdef ChBulk_v1 < handle
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
    end
    
   
    methods
        % Constructor
        function obj = ChBulk_v1(param,station)
            obj.Mode = param.channel.mode;
            obj.Tx_pos = station.Position;
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
                case 'fading'
                    out = lteFadingChannel(struct(obj),station.TxWaveform);
                case 'mobility'
                    out = lteMovingChannel(struct(obj),station.TxWaveform);
                case 'macro_METIS'
                    % Get position and configuration of eNB (tx)
                    
                    
                    % Get position of user
                    user_pos = rx.position;
                    
                    % Compute FPL given distance and BS configuration
                    
                    % Compute Multiple screen diffraction loss (Lmsd)
                    
                    % Compute Diffraction from the rootop down to the street level (Lrts)
  
                    % Combine signal
                    
                    out = tx.TxWaveform;
                    
                    
                case 'micro_METIS'
                    
                    out = tx.TxWaveform;
            end
            
        end
        
        
        
    end
        
        
        
        
    
end