function [schFlag, enb] = shouldSchedule(enb, Users)

%   SHOULD SCHEDULE is used to check power state and whether an eNodeB should schedule
%
%   Function fingerprint
%   enb			->	eNodeB
%		Users		->	Users
%
%   schFlag	->	whether the enb should schedule

	schFlag = false;
	if ~isempty(find([enb.Users.UeId] ~= -1)) 
		% There are users connected, filter them from the Users list and check the queue
		enbUsers = Users(find([Users.ENodeBID] == enb.NCellID));
		queueStatus = false;
		for iUser = 1:length(enbUsers)
			if enbUsers(iUser).Queue.Size > 0 
				queueStatus = true;
				break;
			end
		end
		if (queueStatus)
			% Now check the power status of the eNodeB
			if ~isempty(find([1, 2, 3] == enb.PowerState))
				% Normal, underload and overload => the eNodeB can schedule
				schFlag = true; 
			elseif ~isempty(find([4, 6] == enb.PowerState))
				% The eNodeB is shutting down or booting up => the eNodeB cannot schedule
				schFlag = false;
			elseif enb.PowerState == 5
				% The eNodeB is inactive, but should be restarted 
				enb = initiateBoot(enb);
			end
		end
	end
end