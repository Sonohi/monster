classdef BackhaulAggregation < matlab.mixin.Copyable

    %Properties of the class
    properties 
        %Parent eNB
        eNB;
        Bandwidth;
        PropagationSpeed;
        LengthOfMedium;
        PropDelay; % Propragation delay
        Traffic; % traffic from the traffic generator
        Queues; %Queues for UEs
        Delay; %Delay in ms
        PrevTime;
        UtilizationLimit;
        TotalBits;
    end

    methods 
        %Constructor
        function obj = BackhaulAggregation(eNB, Traffic, Config)
            obj.eNB = eNB;
            obj.Bandwidth = Config.Backhaul.bandwidth;
            obj.PropagationSpeed = Config.Backhaul.propagationSpeed;
            obj.LengthOfMedium = Config.Backhaul.lengthOfMedium;
            obj.UtilizationLimit = Config.Backhaul.utilizationLimit;
            obj.Traffic = Traffic;
            obj.PropDelay = obj.calculatePropDelay;
            obj.Delay = 0;
            obj.PrevTime = 0;
            obj.TotalBits = 0;
        end

        function propDelay = calculatePropDelay(obj)
            %Calculate the round trip time in s
            propDelay = (obj.LengthOfMedium / obj.PropagationSpeed); %[s]
        end

        function transDelay = calculateTransDelay(obj, users, simTime)
            %Calculate amount of bits send since last frame
            totalBits = obj.getTotalBits(users, simTime);
            %Calculate transmission delay in s
            transDelay = totalBits/obj.Bandwidth; % [s]
        end

        function totalBits = getTotalBits(obj, users, simTime)
            totalBits = 0; %Reset for each calculation

            for iUser = 1:length(users)
                trafficId = users(iUser).Traffic.generatorId;
                % First, check whether the arrival time of this UE allows it to start
                if users(iUser).Traffic.startTime <= simTime
                    % first off check the id/index of the next packet to be put into the queue
                    pktIx = users(iUser).Queue.Pkt;
                    if pktIx >= length(obj.Traffic(trafficId).TrafficSource)
                        pktIx = 1;
                    end
                    % Get all packets from the source portion that have a delivery time before the current simTime
                    for iPkt = pktIx:length(obj.Traffic(trafficId).TrafficSource)
                        if obj.Traffic(trafficId).TrafficSource(iPkt, 1) <= simTime && obj.Traffic(trafficId).TrafficSource(iPkt, 1) >= obj.PrevTime
                            % increase frame size
                            totalBits = totalBits + obj.Traffic(trafficId).TrafficSource(iPkt, 2);
                        else
                            % all packets in this delivery window have been added
                            break;
                        end
                    end
                end
            end
            %Set for metric recorder
            obj.TotalBits = totalBits;
        end

        function updateAllQueues(obj, users, simTime)
            %Calculate Transmission delay
            transDelay = obj.calculateTransDelay(users, simTime);

            %Check if any traffic has arrived from the traffic generator and calculate utilization
            bwUse = obj.bandwidthUtilization(users, simTime);
            delay = 0; %Reset from last round
            if bwUse > obj.UtilizationLimit %Congestion
                %find number of bits exceeding the limit.
                nBits = bwUse - obj.UtilizationLimit;
                % apply extra transmission delay
                delay = delay + nBits/obj.Bandwidth;
            end

            % Add delay from last round
            if obj.Delay > simTime-obj.PrevTime
                delay = delay + obj.Delay-(simTime-obj.PrevTime);
            end
            % apply propragation and transmission delay
            delay = delay + obj.PropDelay + transDelay;
            %Store information for next round
            obj.Delay = delay;
            obj.PrevTime = simTime;

            %Update the queues accordingly
            for iUser=1:length(users)
                Queues(iUser)= obj.updateQueue(users(iUser), simTime, delay);
            end
            obj.Queues = Queues;
        end

        function bwUse = bandwidthUtilization(obj, users, simTime)
            %Calculate the total amount of incoming bits.
            totalBits = obj.getTotalBits(users, simTime);
            bwUse = totalBits/obj.Bandwidth;
        end

        function queue = updateQueue(obj, User, simTime, delay)
            newQueue = User.Queue;
            %find the traffic source
            trafficId = User.Traffic.generatorId;

			% First, check whether the arrival time of this UE allows it to start
			if User.Traffic.startTime <= simTime
				% first off check the id/index of the next packet to be put into the queue
				pktIx = User.Queue.Pkt;
				if pktIx >= length(obj.Traffic(trafficId).TrafficSource)
					pktIx = 1;
				end

				% Get all packets from the source portion that have a delivery time before the current simTime
				for iPkt = pktIx:length(obj.Traffic(trafficId).TrafficSource)
					if obj.Traffic(trafficId).TrafficSource(iPkt, 1) <= simTime + delay
						% increase frame size and update frame delivery deadline
						newQueue.Size = newQueue.Size + obj.Traffic(trafficId).TrafficSource(iPkt, 2);
						newQueue.Time = obj.Traffic(trafficId).TrafficSource(iPkt, 1);
					else
						% all packets in this delivery window have been added, save the ID of the next
						newQueue.Pkt = iPkt;
						break;
					end
				end

            end

            queue = newQueue;
        end


    end
end