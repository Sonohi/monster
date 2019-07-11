function [Traffic, Users] = setupTraffic (Users, Config, Logger)
	% setupTraffic - performs the necessary setup for the traffic in the simulation
	%
	% :param Users: Aray<UserEquipment> array of UEs class instances
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Users: Aray<UserEquipment> array of UEs class instances
	% :returns Traffic: Array<TrafficGenerator> simulation Traffic class instances

	Logger.log('(SETUP - setupTraffic) setting up traffic', 'DBG');
	thresholdPrimary = ceil(Config.Traffic.mix*length(Users));
	totIds = [Users.NCellID];
	if thresholdPrimary == 0
		Logger.log('(SETUP - setupTraffic) creating primary traffic model for all UEs', 'DBG');
		Traffic(1) = TrafficGenerator(Config.Traffic.primary, totIds, Config, 1, Logger);
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
	elseif thresholdPrimary == length(Users)
		Logger.log('(SETUP - setupTraffic) creating secondary traffic model for all UEs', 'DBG');
		Traffic(1) = TrafficGenerator(Config.Traffic.secondary, totIds, Config, 1, Logger);
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
	else
		Logger.log('(SETUP - setupTraffic) creating primary and secondary traffic model for UEs', 'DBG');
		Traffic(1) = TrafficGenerator(Config.Traffic.primary, totIds(1:thresholdPrimary), Config, 1, Logger);
		Traffic(2) = TrafficGenerator(Config.Traffic.secondary, totIds(thresholdPrimary + 1: length(Users)), Config, 2, Logger);	
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
		trafficGenAllocation(thresholdPrimary + 1: length(Users)) = 2;
	end	
	
	% Assign a start time for the traffic to each UE based on the traffic generator
	for iUser = 1: length(Users)
		Users(iUser).Traffic.generatorId = trafficGenAllocation(iUser);
		Users(iUser).Traffic.startTime = Traffic(trafficGenAllocation(iUser)).getStartingTime(Users(iUser).NCellID, Logger);
	end
	
end
	