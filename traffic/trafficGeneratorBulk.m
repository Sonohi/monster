function [Users, TrafficGenerators] = trafficGeneratorBulk(Users, Param)
% trafficGeneratorBulk - This is used to create traffic generators in bulk, assign UEs to traffic generators and starting time to UEs
% ::
% 	[Users, TrafficGenerators] = trafficGeneratorBulk(Users, Param)

	% Check the traffic mix value and split the UEs
	if (Param.trafficMix >= 0)
		thresholdPrimary = ceil(Param.trafficMix*length(Users));
		totIds = [Users.NCellID];
		if thresholdPrimary == 0
			sonohilog('(TRAFFIC GENERATOR BULK) there will only be UEs for the primary traffic profile', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Param.primaryTrafficModel, totIds, Param);
		elseif thresholdPrimary == length(Users)
			sonohilog('(TRAFFIC GENERATOR BULK) there will only be UEs for the secondary traffic profile', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Param.secondaryTrafficModel, totIds, Param);
		else
			sonohilog('(TRAFFIC GENERATOR BULK) there will UEs for both traffic profiles', 'NFO');
			TrafficGenerators(1) = TrafficGenerator(Param.primaryTrafficModel, totIds(1:thresholdPrimary), Param);
			TrafficGenerators(2) = TrafficGenerator(Param.secondaryTrafficModel, totIds(thresholdPrimary + 1: length(Users)), Param);	
		end	
		
		% Now loop through the UEs to assign their start time
		for iUser = 1:length(Users)
			UeTrafficGenerator = getTrafficGenerator(Users(iUser).NCellID, TrafficGenerators);
			Users(iUser).TrafficStartTime = UeTrafficGenerator.getStartingTime(Users(iUser).NCellID);
		end
	else
		sonohilog('(TRAFFIC GENERATOR BULK) traffic mix cannot be negative', 'ERR');
	end
end