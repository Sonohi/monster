function [Station, Users] = schedule(Station, Users, Param)

%   SCHEDULE is used to return the allocation of PRBs for a schedule
%
%   Function fingerprint
%   Station					->  base Station
%		Users						-> 	users list
%   Param.prbSym		->  number of OFDM symbols per PRB
%
%   Station		->  station with allocation array with:
%             		--> ueId		id of the UE scheduled in that slot
%									--> mcs 		modulation and coding scheme decided
%									--> modOrd	modulation order as bits/OFDM symbol

% reset the allocation
Station = resetScheduleDL(Station);
sz = length(Station.Users);

% calculate number of available RBs available in the subframe for the PDSCH
res = length(find(abs(Station.Tx.ReGrid) == 0));
prbsAv = floor(res/Param.prbRe);

switch Param.scheduling
	case 'roundRobin'
		
		maxRounds = sz;
		iUser = Station.RrNext.Index;
		while (iUser <= sz && maxRounds > 0)
			% First off check if we are in an unused position or out
			iUser = checkIndexPosition(Param, Station, iUser);
			
			% find user in main list
			for ixUser = 1:length(Users)
				if Users(ixUser).NCellID == Station.Users(iUser).UeId
					iCurrUe = ixUser;
					break;
				end
			end

			% If the retransmissions are on, check awaiting retransmissions
			rtxInfo = struct('proto', [], 'identifier', [], 'iUser', -1);
			if Param.rtxOn
				rtxInfo = checkRetransmissionQueues(Station, Users(iCurrUe).NCellID);
			end

			% Boolean flags for scheduling for readability
			schedulingFlag = ~Users(iCurrUe).Scheduled;
			noRtxSchedulingFlag = Users(iCurrUe).Queue.Size > 0 && (~Param.rtxOn || ...
														(Param.rtxOn && rtxInfo.proto == 0));
			rtxSchedulingFlag = Param.rtxOn && rtxInfo.proto ~= 0;
			
			% If there are still PRBs available, then we can schedule either a new TB or a RTX
			if prbsAv > 0
				if schedulingFlag && (noRtxSchedulingFlag || rtxSchedulingFlag)
					modOrd = cqi2modOrd(Users(iCurrUe).Rx.CQI);
					if noRtxSchedulingFlag
						prbsNeed = ceil(Users(iCurrUe).Queue.Size/(modOrd * Param.prbSym));
					else
						% In this case load the TB picked for retransmission
						tb = [];
						switch rtxInfo.proto
							case 1
								tb = Station.Mac.HarqTxProcesses(rtxInfo.iUser).processes(rtxInfo.identifier).tb;
							case 2
								tb = Station.Rlc.ArqTxBuffers(rtxInfo.iUser).tbBuffer(rtxInfo.identifier).tb;
						end
						prbsNeed = ceil(length(tb)/(modOrd * Param.prbSym));
					end
					if prbsNeed >= prbsAv
						prbsSch = prbsAv;
					else
						prbsSch = prbsNeed;
					end
					
					prbsAv = prbsAv - prbsSch;
					Users(iCurrUe) = setScheduled(Users(iCurrUe), true);
					if rtxSchedulingFlag
						Station = initRetransmission(Station, rtxInfo);
					end
					% write to schedule struct
					for iPrb = 1:Station.NDLRB
						if Station.ScheduleDL(iPrb).UeId == 0
							mcs = cqi2mcs(Users(iCurrUe).Rx.CQI);
							for iSch = 0:prbsSch-1
								Station.ScheduleDL(iPrb + iSch) = struct(...
									'UeId', Users(iCurrUe).NCellID,...
									'Mcs', mcs,...
									'ModOrd', modOrd);
							end
							break;
						end
					end
					
					% In case the UE is not receiving all the PRBs needed, the next loop
					% will start again from it and we stop this round, otherwise
					% continue
					if prbsNeed > prbsSch
						Station.RrNext.UeId = Station.Users(iUser).UeId;
						Station.RrNext.Index = iUser;
						iUser = sz + 1;
					else
						iUser = iUser + 1;
					end
					
				end
				maxRounds = maxRounds - 1;
				
			else
				% There are no more PRBs available, this will be the first UE to be scheduled
				% in the next round.
				% Check first whether we went too far in the list and we need to restart
				% from the beginning
				iUser = checkIndexPosition(Param, Station, iUser);
				Station.RrNext.UeId = Station.Users(iUser).UeId;
				Station.RrNext.Index = iUser;
				
				% in both cases, stop the loop
				iUser = sz + 1;
			end			
		end
	end

	function iUser = checkIndexPosition(Param, Station, iUser)
		if iUser > Param.numUsers || Station.Users(iUser).UeId == -1
			iUser = 1;
		end
	end

end
