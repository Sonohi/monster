function [sch] = checkUserSchedule(User, Station)

%   CHECK USER SCHEDULE is used to check if a user is scheduled in the round
%
%   Function fingerprint
%   User			->  User to check
%   Station		->  associated Station
%
%   sch				->  boolean with answer


	sch = false;
	for (iPRB = 1:length(Station.Schedule))
		if (Station.Schedule(iPRB).UeId == User.UeId && User.Queue.Size > 0)
			sch = true;
			break;
		end
	end
end
