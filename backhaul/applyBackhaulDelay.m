function Traffic = applyBackhaulDelay(TrafficIn, Config)
    %Calculate the delayed arrival times at the eNB for each user. 
    %This assumes infinite queue at ingress

    Traffic = copy(TrafficIn);
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
    %Number of errors
    numErrors = 0;
    for iRound = 1:Config.Runtime.totalRounds
        
        %Add incoming data to the queue
        for iUser = 1:Config.Ue.number
            %Find traffic source for the chosen ID
            for iTraffic = 1:length(TrafficIn)
                if TrafficIn(iTraffic).AssociatedUeIds(TrafficIn(iTraffic).AssociatedUeIds==iUser)
                    for iArrivalTime = 1:length(TrafficIn(iTraffic).TrafficSource(:,1) )
                        if TrafficIn(iTraffic).TrafficSource(iArrivalTime,1) <= t && TrafficIn(iTraffic).TrafficSource(iArrivalTime,1) > t-10^(-3)
                            dataQueue(iUser) = dataQueue(iUser) + TrafficIn(iTraffic).TrafficSource(iArrivalTime,2);
                        elseif TrafficIn(iTraffic).TrafficSource(iArrivalTime,1) > t
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
               data(dataQueue >= bitRate/Config.Ue.number) =bitRate/Config.Ue.number;
               data(dataQueue < bitRate/Config.Ue.number) = dataQueue(dataQueue < bitRate/Config.Ue.number);
               dataQueue = dataQueue -data;
               while ~dataQueue(dataQueue < 0)
                  %Redistribute where the data should go.
                  %TODO: add scheduler to utilize full bandwidth

                  break;
               end
               transDelay = 10^(-3);
        else 
            data = dataQueue;
            dataQueue = zeros(Config.Ue.number,1); %Reset dataQueue as all data is emptied from it.
            transDelay = totalBits/bitRate*10^(-3);
        end
        %Add errors - removes data for a user chosen at random
        if rand <= Config.Backhaul.errorRate
            randUser = randi([1 Config.Ue.number]);
            data(randUser) = data(randUser)*Config.Backhaul.errorMagnitude;
            numErrors = numErrors +1;
        end
        %Add traffic
        TrafficSource(iRound , 2 ,:) = data;
        %Add delay times
        TrafficSource(iRound , 1 ,:) = propDelay + transDelay + Config.Backhaul.switchDelay + t;
        t = t+10^(-3);
    end
    
    %Add new trafficSource to Traffic struct
    for iUser = 1:Config.Ue.number
        %Find traffic source for the chosen ID
        for iTraffic = 1:length(TrafficIn)
            if TrafficIn(iTraffic).AssociatedUeIds(TrafficIn(iTraffic).AssociatedUeIds==iUser)
                Traffic(iUser) = copy(TrafficIn(1));
                Traffic(iUser).Id = iUser;
                Traffic(iUser).TrafficType = TrafficIn(iTraffic).TrafficType;
                Traffic(iUser).ArrivalMode = TrafficIn(iTraffic).ArrivalMode;
                Traffic(iUser).TrafficSource = TrafficSource(:,:,iUser);
                Traffic(iUser).AssociatedUeIds = iUser;
                Traffic(iUser).ArrivalTimes = TrafficIn(iTraffic).ArrivalTimes(TrafficIn(iTraffic).AssociatedUeIds==iUser);
                break;
            end
        end
    end
end