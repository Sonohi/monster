function [Station, Users] = schedule(Station, Users, Config)
	% schedule links UEs to a eNodeB
	%
	% :Station: EvolvedNodeB instance
	% :Users: Array<UserEquipment> instances
	% :Config: MonsterConfig instance
	%
	% :Station: EvolvedNodeB instance with updated scheduling
	% :Users: Array<UserEquipment> instances with scheduling slots
	%

% Set a flag for the overall number of valid UE attached
sz = length(extractUniqueIds([Station.Users.UeId]));

% Set initially the number of available PRBs to the entire set
prbsAv = Station.NDLRB;

% get ABS info
% current subframe
currentSubframe = Station.NSubframe;
absValue = Station.AbsMask(currentSubframe + 1); % get a 0 or 1 that corresponds to the mask of this subframe

% if the policy is simpleABS, we use the fixed ABS mask from the Station
% properties
if (strcmp(Config.Scheduling.icScheme, 'simpleABS'))
	if(~strcmp(Station.BsClass, 'macro'))
		% the behavior of the micro is the opposite of that of the macro
		absValue = ~absValue;
	end
	prbsAv = (1 - absValue) * prbsAv; % set the number of available PRBs to
	% zero when the absValue is 1, i.e., when we have an almost blank
	% subframe
elseif (strcmp(Config.Scheduling.icScheme, 'fullReuseABS'))
	if(strcmp(Station.BsClass, 'macro')) % micros can always transmit
		prbsAv = (1 - absValue) * prbsAv;
		% set the number of available PRBs to
		% zero when the absValue is 1, i.e., when we have an almost blank
		% subframe
	end
end

switch Config.Scheduling.type
	case 'roundRobin'
		
		maxRounds = sz;
		iUser = Station.RoundRobinDLNext.Index;
		while (iUser <= sz && maxRounds > 0)
			% First off check if we are in an unused position or out
			iUser = checkIndexPosition(Station, iUser, sz);
			
			% find user in main list
			for ixUser = 1:length(Users)
				if Users(ixUser).NCellID == Station.Users(iUser).UeId
					iCurrUe = ixUser;
					break;
				end
			end
			
			% If the retransmissions are on, check awaiting retransmissions
			rtxInfo = struct('proto', [], 'identifier', [], 'iUser', -1);
			if Config.Harq.active
				% RLC queue check
				iUserRlc = find([Station.Rlc.ArqTxBuffers.rxId] == Users(iCurrUe).NCellID);
				arqRtxInfo = Station.Rlc.ArqTxBuffers(iUserRlc).getRetransmissionState();

				% MAC queues check
				iUserMac = find([Station.Mac.HarqTxProcesses.rxId] == Users(iCurrUe).NCellID);
				harqRtxInfo = Station.Mac.HarqTxProcesses(iUserMac).getRetransmissionState();

				% HARQ retransmissions have the priority 
				if harqRtxInfo.flag
					rtxInfo.proto = 1;
					rtxInfo.identifier = harqRtxInfo.procIndex;
					rtxInfo.iUser = iUserMac;
				elseif arqRtxInfo.flag
					rtxInfo.proto = 2;
					rtxInfo.identifier = arqRtxInfo.bufferIndex;
					rtxInfo.iUser = iUserRlc;
				else
					rtxInfo.proto = 0;
					rtxInfo.identifier = [];
				end
			end
			
			% Boolean flags for scheduling for readability
			schedulingFlag = ~Users(iCurrUe).Scheduled.DL;
			noRtxSchedulingFlag = Users(iCurrUe).Queue.Size > 0 && (~Config.Harq.active || ...
				(Config.Harq.active && rtxInfo.proto == 0));
			rtxSchedulingFlag = Config.Harq.active && rtxInfo.proto ~= 0;
			
			% If there are still PRBs available, then we can schedule either a new TB or a RTX
			if prbsAv > 0
				if schedulingFlag && (noRtxSchedulingFlag || rtxSchedulingFlag)
					modOrd = Config.Phy.modOrdTable(Users(iCurrUe).Rx.CQI);
					if noRtxSchedulingFlag
						prbsNeed = ceil(double(Users(iCurrUe).Queue.Size)/(modOrd * Config.Phy.prbSymbols));
					else
						% In this case load the TB picked for retransmission
						tb = [];
						switch rtxInfo.proto
							case 1
								tb = Station.Mac.HarqTxProcesses(rtxInfo.iUser).processes(rtxInfo.identifier).tb;
							case 2
								tb = Station.Rlc.ArqTxBuffers(rtxInfo.iUser).tbBuffer(rtxInfo.identifier).tb;
						end
						prbsNeed = ceil(length(tb)/(modOrd * Config.Phy.prbSymbols));
					end
					if prbsNeed >= prbsAv
						prbsSch = prbsAv;
					else
						prbsSch = prbsNeed;
					end
					
					prbsAv = prbsAv - prbsSch;
					% Set the scheduled flag in the UE
					Users(iCurrUe).Scheduled.DL = true;
					if rtxSchedulingFlag
						switch rtxInfo.proto
							case 1
								Station.Mac.HarqTxProcesses(rtxInfo.iUser) = ...
									setRetransmissionState(Station.Mac.HarqTxProcesses(rtxInfo.iUser), rtxInfo.identifier);
							case 2
								Station.Rlc.ArqTxBuffers(rtxInfo.iUser) = ...
									setRetransmissionState(Station.Rlc.ArqTxBuffers(rtxInfo.iUser), rtxInfo.identifier);
						end
					end

					% write to schedule struct and indicate also in the struct whether this is new data or RTX
					for iPrb = 1:Station.NDLRB
						if Station.ScheduleDL(iPrb).UeId == -1
							mcs = Config.Phy.mcsTable(Users(iCurrUe).Rx.CQI + 1, 1);
							for iSch = 0:prbsSch-1
								Station.ScheduleDL(iPrb + iSch) = struct(...
									'UeId', Users(iCurrUe).NCellID,...
									'Mcs', mcs,...
									'ModOrd', modOrd,...
									'NDI', noRtxSchedulingFlag);
							end
							break;
						end
					end
					
					% Increment the user counter to serve the next one
					iUser = iUser + 1;
					
					% Check the index of the user to handle a possible reset
					iUser = checkIndexPosition(Station, iUser, sz);
					
				end
				maxRounds = maxRounds - 1;
				
			else
				% There are no more PRBs available, this will be the first UE to be scheduled
				% in the next round.
				% Check first whether we went too far in the list and we need to restart
				% from the beginning
				iUser = checkIndexPosition(Station, iUser, sz);
				Station.RoundRobinDLNext.UeId = Station.Users(iUser).UeId;
				Station.RoundRobinDLNext.Index = iUser;
				
				% in both cases, stop the loop
				iUser = sz + 1;
			end
		end
end

	function validIndex = checkIndexPosition(Station, iUser, sz)
		if iUser > sz || Station.Users(iUser).UeId == -1
			% In this case we need to reset to the first active and valid UE
			validUeIndexes = find([Station.Users.UeId] ~= -1);
			validIndex = validUeIndexes(1);
		else
			validIndex = iUser;
		end
	end

end
