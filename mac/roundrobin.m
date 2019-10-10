function [mapping, updatedqueue] = roundrobin(users, queue, prbs, harqActive)

	% <users> array of struct with the fields: UeId, arqRtxInfo, harqRtxInfo, Scheduled, Queue, ModOrder, CQI


	% Compute number of available resources
	numPRBs = length(prbs);

	% TODO: add abs mask here

	PRBAvailable = numPRBs;

	% Get user Ids from previous round
	userIds = [users.UeId];

	if ~isempty(queue)
		queueIds = [queue.UeId];
		userIds = [queueIds userIds(userIds ~= queueIds)];
	else
		queueIds = [];
	end

	% userIds is now a prioritized list of users, with queued users placed first

	maxIterations = numPRBs;
	
	while maxIterations > 0
		iUserID = userIds(1); % Get first from userids
		iUser = users(iUserID  == users.UeId);

		% Condition cases
		% check the users has been scheduled.

		% pop user from list
		userIds = userIds(2:end);

		% If the retransmissions are on, check awaiting retransmissions
		rtxInfo = struct('proto', [], 'identifier', [], 'iUser', -1);
		if harqActive
			% Get RLC queue
			arqRtxInfo = iUser.arqRtxInfo;
			arqTxProcesses = Cell.Rlc.ArqTxBuffers(iUser); % TODO: check that this is a shallow copy

			% Get MAC queue
			harqRtxInfo = iUser.harqRtxInfo;
			harqTxProcesses = Cell.Mac.HarqTxProcesses(iUser);
			if harqRtxInfo.flag
				rtxInfo.proto = 1;
				rtxInfo.identifier = harqRtxInfo.procIndex;
				rtxInfo.iUser = iUser;
			elseif arqRtxInfo.flag
				rtxInfo.proto = 2;
				rtxInfo.identifier = arqRtxInfo.bufferIndex;
				rtxInfo.iUser = iUser;
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
			modOrd = iUser.ModOrd;

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
			for iPrb = 1:Cell.NDLRB
				if Cell.ScheduleDL(iPrb).UeId == -1
					mcs = Config.Phy.mcsTable(iUser.Rx.CQI + 1, 1);
					for iSch = 0:prbsSch-1
						Cell.ScheduleDL(iPrb + iSch) = struct(...
							'UeId', iUser.NCellID,...
							'Mcs', mcs,...
							'ModOrd', modOrd,...
							'NDI', noRtxSchedulingFlag);
					end
					break;
				end
			end
						
		maxRounds = maxRounds - 1;
			
		else
			% There are no more PRBs available, this will be the first UE to be scheduled
			% in the next round.
			% Check first whether we went too far in the list and we need to restart
			% from the beginning
			Cell.RoundRobinDLNext.UeId = iUser.NCellID;

		end
	end	
end