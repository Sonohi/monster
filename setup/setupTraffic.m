function [Traffic, Users] = setupTraffic (Users, Config)
	% setupTraffic - performs the necessary setup for the traffic in the simulation
	%	
	% Syntax: Traffic = setupTraffic(Users, Config)
	% Parameters:
	% :Users: (Aray<UserEquipment>) array of UEs class instances
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Users: (Aray<UserEquipment>) array of UEs class instances
	% :Traffic: (Array<TrafficGenerator>) simulation Traffic class instances

	monsterLog('(SETUP - setupTraffic) setting up traffic', 'NFO');
	thresholdPrimary = ceil(Config.Traffic.mix*length(Users));
	totIds = [Users.NCellID];
	if thresholdPrimary == 0
		monsterLog('(SETUP - setupTraffic) creating primary traffic model for all UEs', 'NFO');
		Traffic(1) = TrafficGenerator(Config.Traffic.primary, totIds, Config, 1);
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
	elseif thresholdPrimary == length(Users)
		monsterLog('(SETUP - setupTraffic) creating secondary traffic model for all UEs', 'NFO');
		Traffic(1) = TrafficGenerator(Config.Traffic.secondary, totIds, Config, 1);
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
	else
		monsterLog('(SETUP - setupTraffic) creating primary and secondary traffic model for UEs', 'NFO');
		Traffic(1) = TrafficGenerator(Config.Traffic.primary, totIds(1:thresholdPrimary), Config, 1);
		Traffic(2) = TrafficGenerator(Config.Traffic.secondary, totIds(thresholdPrimary + 1: length(Users)), Config, 2);	
		% Define allocation ranges
		trafficGenAllocation = ones(1, length(Users));
		trafficGenAllocation(thresholdPrimary + 1: length(Users)) = 2;
	end	
	
	% Assign a start time for the traffic to each UE based on the traffic generator
	for iUser = 1: length(Users)
		Users(iUser).Traffic.generatorId = trafficGenAllocation(iUser);
		Users(iUser).Traffic.startTime = Traffic(trafficGenAllocation(iUser)).getStartingTime(Users(iUser).NCellID);
	end
	
end
	