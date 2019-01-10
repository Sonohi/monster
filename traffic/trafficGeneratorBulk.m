function [Users, TrafficGenerators] = trafficGeneratorBulk(Users, Config)
% trafficGeneratorBulk - This is used to create traffic generators in bulk, assign UEs to traffic generators and starting time to UEs
% ::
% 	[Users, TrafficGenerators] = trafficGeneratorBulk(Users, Config)

	% Check the traffic mix value and split the UEs
	if (Config.Traffic.mix >= 0)
		thresholdPrimary = ceil(Config.Traffic.mix*length(Users));
		totIds = [Users.NCellID];
		if thresholdPrimary == 0
			monsterLog('(TRAFFIC GENERATOR BULK) there will only be UEs for the primary traffic profile', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Config.Traffic.primary, totIds, Config);
		elseif thresholdPrimary == length(Users)
			monsterLog('(TRAFFIC GENERATOR BULK) there will only be UEs for the secondary traffic profile', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Config.Traffic.secondary, totIds, Config);
		else
			monsterLog('(TRAFFIC GENERATOR BULK) there will UEs for both traffic profiles', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Config.Traffic.primary, totIds(1:thresholdPrimary), Config);
			TrafficGenerators(2) = TrafficGenerator(Config.Traffic.secondary, totIds(thresholdPrimary + 1: length(Users)), Config);	
		end	
		
		% Now loop through the UEs to assign their start time
		for iUser = 1:length(Users)
			UeTrafficGenerator = getTrafficGenerator(Users(iUser).NCellID, TrafficGenerators);
			Users(iUser).TrafficStartTime = UeTrafficGenerator.getStartingTime(Users(iUser).NCellID);
		end
	else
		monsterLog('(TRAFFIC GENERATOR BULK) traffic mix cannot be negative', 'ERR');
	end
end