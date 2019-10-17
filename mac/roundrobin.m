function [prbs, updatedqueue] = roundrobin(cell, userIds, users, prbs, prbsNeeded, Config)

	% <users> array of users
	% <queueIds> array of queued user ids
	% <scheduledIds> 
	% <prbs> int: number of PRBs
	% <harqActive> bool: if Harq is active


	% Compute number of available resources
	PRBAvailable = length(prbs);

	% userIds is now a prioritized list of users, with queued users placed first
	resourcesAvailable = 1;
	
	while resourcesAvailable
		iUserID = userIds(1); % Get first from userids
		iUser = users([users.NCellID] == iUserID);

		% If there are still PRBs available, then we can schedule either a new TB or a RTX
		if PRBAvailable > 0
			
			PRBNeed = prbsNeeded(1);

			% Check if the PRBs needed are more than what is available
			if PRBNeed >= PRBAvailable
				PRBScheduled = PRBAvailable;
			else
				PRBScheduled = PRBNeed;
			end
				
			PRBAvailable = PRBAvailable - PRBScheduled;

			% Update list of PRBs
			for iPrb = 1:length(prbs)
				if prbs(iPrb).UeId == -1
					mcs = Config.Phy.mcsTable(iUser.Rx.CQI + 1, 1);
					modOrd = Config.Phy.modOrdTable(iUser.Rx.CQI);
					%rtxSchedulingFlag = harqActive && rtxInfo.proto ~= 0;	
					for iSch = 0:PRBScheduled-1
						prbs(iPrb + iSch).UeId = iUser.NCellID;
						prbs(iPrb + iSch).MCS = mcs;
						prbs(iPrb + iSch).ModOrd = modOrd;
					end
					break;
				end
			end
			
			
			% pop user from list
			if length(userIds) > 1
				userIds = userIds(2:end);
				prbsNeeded = prbsNeeded(2:end);
			else
				userIds = [];
				prbsNeeded = [];
				resourcesAvailable = 0; % No more users to schedule
			end

		
			
		else
			% There are no more PRBs available, this will be the first UE to be scheduled
			% in the next round.
			resourcesAvailable = 0;

		end
	end
	
	% Add remaining users to the queue
	updatedqueue = userIds;
	
	
end