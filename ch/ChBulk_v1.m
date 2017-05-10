classdef ChBulk_v1 < matlab.mixin.SetGet
    properties
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
        Mode;
        SamplingRate;
        Seed;
        MovingScenario;
        InitTime;
        User;
    end
   
    methods
        % Constructor
        function obj = ChBulk_v1(param)
            
            switch param.channel.mode
                
                % Standard mobility case ref:
                % [https://se.mathworks.com/help/lte/ref/ltemovingchannel.html]
                case 'mobility'
                    obj.NRxAnts = 1;
                    obj.NormalizeTxAnts = 'On';
                    obj.DelayProfile = 'ETU';
                    obj.DopplerFreq = 70;
                    obj.MIMOCorrelation = 'Low';
                    obj.NTerms = 16;
                    obj.ModelType = 'GMEDS';
                    obj.InitPhase = 'Random';
                    obj.NormalizePathGains = 'On';
                    obj.Mode = param.channel.mode;
                    obj.MovingScenario = 'Scenario1';
                    obj.InitTime = 0;
                
                % Standard fading channel ref:
                % [https://se.mathworks.com/help/lte/ref/ltefadingchannel.html]
                case 'fading'
                    obj.NRxAnts = 1;
                    obj.DelayProfile = 'EPA';
                    obj.MIMOCorrelation = 'Low';
                    obj.InitPhase = 'Random';
                    obj.ModelType = 'GMEDS';
                    obj.NTerms = 16;
                    obj.NormalizeTxAnts = 'On';
                    obj.NormalizePathGains = 'On';
            end
                
                
        end
        
        
        % Function for setting sampling rate (given by OFDM info of eNB)
        function obj = set.SamplingRate(obj,sampling_rate)
            obj.SamplingRate = sampling_rate;
        end
        
        % Function for setting Seed
        function obj = set.Seed(obj,seed)
            obj.Seed = seed;
        end
        
        % Function for setting user id
        function obj = set.User(obj,userID)
            obj.User = userID;
        end
        
        
        % Propagate
        function out = propagate(obj,signal)
            warning off MATLAB:structOnObject
            switch obj.Mode
                case 'fading'
                out = lteFadingChannel(struct(obj),signal)
                case 'mobility'
                out = lteMovingChannel(struct(obj),signal) 
            end
            
        end
        
        
        
    end
        
        
        
        
    
end