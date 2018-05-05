function Users = updateQueuesBulk(Users, TrafficGenerators, simTime)
% getTrafficGenerator - This is used to determine which traffic generator a UE is associated with
%
% Syntax: TrafficGenerator = getTrafficGenerator(UeId, TrafficGenerators)

	for iUser = 1: length(Users)
		UeTrafficGenerator = getTrafficGenerator(Users(iUser).NCellID, TrafficGenerators);
		Users(iUser).Queue = UeTrafficGenerator.updateTransmissionQueue(Users(iUser), simTime);
	end
end