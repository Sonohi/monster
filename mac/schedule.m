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
Station = resetSchedule(Station);
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
			iUSer = checkIndexPosition(Param, Station, iUser);
			
			% find user in main list
			for (ixUser = 1:length(Users))
				if (Users(ixUser).UeId == Station.Users(iUser))
					iCurrUe = ixUser;
					break;
				end
			end

			% If the retransmissions are on, then check beforehand whether this UE has anything to be sent
			retransmissionsInfo = struct('flag', false, 'sqn', -1, 'harq');
			if Param.rtxOn
				retransmissionsInfo = checkRetransmissionQueues(Station, Users(iCurrUe).UeId);
			end
			
			if prbsAv > 0
				if ~Users(iCurrUe).Scheduled && Users(iCurrUe).Queue.Size > 0
					modOrd = cqi2modOrd(Users(iCurrUe).Rx.WCQI);
					prbsNeed = ceil(Users(iCurrUe).Queue.Size/(modOrd * Param.prbSym));
					prbsSch = 0;
					if prbsNeed >= prbsAv
						prbsSch = prbsAv;
					else
						prbsSch = prbsNeed;
					end
					
					prbsAv = prbsAv - prbsSch;
					Users(iCurrUe) = setScheduled(Users(iCurrUe), true);
					% write to schedule struct
					for iPrb = 1:Station.NDLRB
						if Station.Schedule(iPrb).UeId == 0
							mcs = cqi2mcs(Users(iCurrUe).Rx.WCQI);
							for iSch = 0:prbsSch-1
								Station.Schedule(iPrb + iSch) = struct(...
									'UeId', Users(iCurrUe).UeId,...
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
						Station.RrNext.UeId = Station.Users(iUser);
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
				Station.RrNext.UeId = Station.Users(iUser);
				Station.RrNext.Index = iUser;
				
				% in both cases, stop the loop
				iUser = sz + 1;
			end			
		end
	end

	function iUser = checkIndexPosition(Param, Station, iUser)
		if iUser > Param.numUsers || Station.Users(iUser) == 0
			iUser = 1;
		end
	end

end
