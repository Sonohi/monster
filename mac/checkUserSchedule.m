function [sch] = checkUserSchedule(user, station)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CHECK USER SCHEDULE is used to check if a user is scheduled in the round	 %
%                                                                              %
%   Function fingerprint                                                       %
%   user			->  user to check																						     %
%   station		->  associated station																			     %
%                                                                              %
%   sch			->  boolean with answer 																					 %
%																																							 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	sch = false;
	for (ix = 1:length(station.schedule))
		if (station.schedule(ix).UEID == user.UEID)
			sch = true;
			break;
		end
	end
end
