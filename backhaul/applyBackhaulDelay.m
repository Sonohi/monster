function Traffic = applyBackhaulDelay(TrafficIn, Config)
    %Calculate the delayed arrival times at the eNB for each user. 
    %This assumes infinite queue at ingress

    Traffic = TrafficIn;
    %Calculate propagation delay
    propDelay = Config.Backhaul.lengthOfMedium / Config.Backhaul.propagationSpeed;
    %Calculate maximum available bitrate [bits/ms]
    bitRate = Config.Backhaul.utilizationLimit * Config.Backhaul.bandwidth * 10^(-3);
    %dataQueue
    dataQueue = zeros(Config.Ue.number,1);
    %Time
    t=0;
    %Delayed TrafficSource
    TrafficSource = zeros(Config.Runtime.totalRounds, 2, Config.Ue.number);
    for iRound = 1:Config.Runtime.totalRounds
        
        %Add incoming data to the queue
        for iUser = 1:Config.Ue.number
            %Find traffic source for the chosen ID
            for iTraffic = 1:length(Traffic)
                if Traffic(iTraffic).AssociatedUeIds(Traffic(iTraffic).AssociatedUeIds==iUser)
                    for iArrivalTime = 1:length(Traffic(iTraffic).TrafficSource(:,1) )
                        if Traffic(iTraffic).TrafficSource(iArrivalTime,1) <= t && Traffic(iTraffic).TrafficSource(iArrivalTime,1) > t-10^(-3)
                            dataQueue(iUser) = dataQueue(iUser) + Traffic(iTraffic).TrafficSource(iArrivalTime,2);
                        elseif Traffic(iTraffic).TrafficSource(iArrivalTime,1) > t
                           break; 
                        end
                    end
                    break;
                end
            end
        end
        
        %Calculate amount of arrived data at time t
        totalBits= sum(dataQueue);
        data = zeros(Config.Ue.number,1);
        if totalBits > bitRate %Congestion       
               data = data + bitRate/Config.Ue.number;
               dataQueue = dataQueue -bitRate/Config.Ue.number;
               while ~dataQueue(dataQueue < 0)
                  %Redistribute where the data should go.
                  break;
               end
               transDelay = 10^(-3);
        else 
            data = dataQueue;
            dataQueue = zeros(Config.Ue.number,1); %Reset dataQueue as all data is emptied from it.
            transDelay = totalBits/bitRate*10^(-3);
        end
        %Add traffic
        TrafficSource(iRound , 2 ,:) = data;
        %Add delay times
        TrafficSource(iRound , 1 ,:) = propDelay + transDelay + t;
        t = t+10^(-3);
    end
    
    %Add new trafficSource to Traffic struct
    for iUser = 1:Config.Ue.number
        %Find traffic source for the chosen ID
        for iTraffic = 1:length(Traffic)
            if Traffic(iTraffic).AssociatedUeIds(Traffic(iTraffic).AssociatedUeIds==iUser)
                
                Traffic(iTraffic).TrafficSource = TrafficSource(:,:,iUser);
            end
        end
    end
end