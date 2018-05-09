function TrafficGenerator = getTrafficGenerator(UeId, TrafficGenerators)
% getTrafficGenerator - This is used to determine which traffic generator a UE is associated with
%
% Syntax: TrafficGenerator = getTrafficGenerator(UeId, TrafficGenerators)

	if length(TrafficGenerators) == 1
		TrafficGenerator = TrafficGenerators(1);
	else
		primaryUes = TrafficGenerators(1).associatedUeIds;
		iUser = find(primaryUes == UeId);
		if ~isempty(iUser)
			TrafficGenerator = TrafficGenerators(1);
		else
			TrafficGenerator = TrafficGenerators(2);
		end
end