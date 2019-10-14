function [prbs, updatedqueue] = roundrobin(cell, users, scheduledIds, queueIds, prbs, harqActive, Config)

	% <users> array of struct with the fields: UeId, arqRtxInfo, harqRtxInfo, Scheduled, Queue, ModOrder, CQI
	% <queue> array of struct with fields: UeId, arqRtxInfo, harqRtxInfo, Scheduled, Queue, ModOrder, CQI
	% <prbs> int: number of PRBs
	% <harqActive> bool: if Harq is active


	% Compute number of available resources
	PRBAvailable = length(prbs);

	if ~isempty(queueIds)
		userIds = [queueIds scheduledIds(~ismember(scheduledIds,queueIds))];
	else
		userIds = scheduledIds;
	end

	% userIds is now a prioritized list of users, with queued users placed first
	resourcesAvailable = 1;
	
	while resourcesAvailable
		iUserID = userIds(1); % Get first from userids
		iUser = users([users.NCellID] == iUserID);

		% Condition cases
		% check the users has been scheduled.


		% If the retransmissions are on, check awaiting retransmissions
		rtxInfo = struct('proto', [], 'identifier', [], 'iUser', -1);
		if harqActive
			% RLC queue check
			iUserRlc = find([cell.Rlc.ArqTxBuffers.rxId] == iUserID);
			arqRtxInfo = cell.Rlc.ArqTxBuffers(iUserRlc).getRetransmissionState();

			% MAC queues check
			iUserMac = find([cell.Mac.HarqTxProcesses.rxId] == iUserID);
			harqRtxInfo = cell.Mac.HarqTxProcesses(iUserMac).getRetransmissionState();
			if harqRtxInfo.flag
				rtxInfo.proto = 1;
				rtxInfo.identifier = harqRtxInfo.procIndex;
				rtxInfo.iUser = iUserID;
			elseif arqRtxInfo.flag
				rtxInfo.proto = 2;
				rtxInfo.identifier = arqRtxInfo.bufferIndex;
				rtxInfo.iUser = iUserID;
			else
				rtxInfo.proto = 0;
				rtxInfo.identifier = [];
			end
		end

		% Boolean flags for scheduling for readability
		noRtxSchedulingFlag = iUser.Queue.Size > 0 && (~harqActive || ...
			(harqActive && rtxInfo.proto == 0));
		rtxSchedulingFlag = harqActive && rtxInfo.proto ~= 0;	

		% If there are still PRBs available, then we can schedule either a new TB or a RTX
		if PRBAvailable > 0
			modOrd = Config.Phy.modOrdTable(iUser.Rx.CQI);

			% If the user do no have any retransmissions. PRBS needed are primarily based on the queue size
			if noRtxSchedulingFlag
				PRBNeed = ceil(double(iUser.Queue.Size)/(modOrd * Config.Phy.prbSymbols));
			else
				% Otherwise, use the HARQ and ARQ queues for PRBS
				tb = [];
				switch rtxInfo.proto
					case 1
						tb = harqTxProcesses.processes(rtxInfo.identifier).tb;
					case 2
						tb = arqTxProcesses.tbBuffer(rtxInfo.identifier).tb;
				end
				PRBNeed = ceil(length(tb)/(modOrd * Config.Phy.prbSymbols));
			end
			
			% Check if the PRBs needed are more than what is available
			if PRBNeed >= PRBAvailable
				PRBScheduled = PRBAvailable;
			else
				PRBScheduled = PRBNeed;
			end
				
			PRBAvailable = PRBAvailable - PRBScheduled;
			% Set the scheduled flag in the UE
			iUser.Scheduled.DL = true;
			if rtxSchedulingFlag
				switch rtxInfo.proto
					case 1
						harqTxProcesses.setRetransmissionState(rtxInfo.identifier);
					case 2
						arqTxProcesses.setRetransmissionState(rtxInfo.identifier);
						%Cell.Rlc.ArqTxBuffers(rtxInfo.iUser) = ...
						%	setRetransmissionState(Cell.Rlc.ArqTxBuffers(rtxInfo.iUser), rtxInfo.identifier);
				end
			end

			% write to schedule struct and indicate also in the struct whether this is new data or RTX
			for iPrb = 1:length(prbs)
				if prbs(iPrb).UeId == -1
					mcs = Config.Phy.mcsTable(iUser.Rx.CQI + 1, 1);
					for iSch = 0:PRBScheduled-1
						prbs(iPrb + iSch).UeId = iUser.NCellID;
						prbs(iPrb + iSch).MCS = mcs;
						prbs(iPrb + iSch).ModOrd = modOrd;
						prbs(iPrb + iSch).NDI = noRtxSchedulingFlag;
					end
					break;
				end
			end
			
			
			% pop user from list
			if length(userIds) > 1
				userIds = userIds(2:end);
			else
				userIds = [];
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