function [Station] = schedule(Station, Users, Param, subframeNum)

%   SCHEDULE is used to return the allocation of PRBs for a schedule
%
%   Function fingerprint
%   Station					->  base Station
%		Users						-> 	users list
%   Param.prbSym		->  number of OFDM symbols per PRB
%   subframeNum			->  subframe number (taken from the scheduling round)
%
%   Station		->  station with allocation array with:
%             		--> ueId		id of the UE scheduled in that slot
%									--> mcs 		modulation and coding scheme decided
%									--> modOrd	modulation order as bits/OFDM symbol

	% reset the allocation
	Station = resetSchedule(Station);
	sz = length(Station.Users);

	% calculate number of available RBs available in the subframe for the PDSCH
	res = length(find(abs(Station.ReGrid) == 0));
	prbsAv = floor(res/Param.prbRe);

	switch (Param.scheduling)
		case 'roundRobin'
			if (Station.RrNext.UeId == 0)
				Station.RrNext.UeId = Station.Users(1);
				Station.RrNext.Index = 1;
			end

			maxRounds = sz;
			iUser = Station.RrNext.Index;
			while (iUser <= sz && maxRounds > 0)

				% find user in main list
				for (ixUser = 1:length(Users))
					if (Users(ixUser).UeId == Station.Users(iUser))
						iCurrUe = ixUser;
						break;
					end
				end

				if (prbsAv > 0)
					if (~Users(iCurrUe).Scheduled && Users(iCurrUe).Queue.Size > 0)
						modOrd = cqi2modOrd(Users(iCurrUe).WCqi);
						prbsNeed = ceil(Users(iCurrUe).Queue.Size/(modOrd * Param.prbSym));
						prbsSch = 0;
						if (prbsNeed >= prbsAv)
							prbsSch = prbsAv;
						else
							prbsSch = prbsNeed;
						end
						prbsAv = prbsAv - prbsSch;
						Users(iCurrUe) = setScheduled(Users(iCurrUe), true);
						iUser = iUser + 1;
						% write to schedule struct
						for (iPrb = 1:Station.NDLRB)
							if (Station.Schedule(iPrb).UeId == 0)
								mcs = cqi2mcs(Users(iCurrUe).WCqi);
								for (iSch = 0:prbsSch-1)
									Station.Schedule(iPrb + iSch) = struct('UeId', Users(iCurrUe).UeId,...
										'Mcs', mcs, 'ModOrd', modOrd);
								end
								break;
							end
						end
					end
					maxRounds = maxRounds -1;

				else
					% Keep track of the next user to be scheduled in the next round
					if (iUser + 1 > sz || Station.Users(iUser + 1) == 0)
						Station.RrNext.UeId = Station.Users(1);
						Station.RrNext.Index = 1;
					else
						Station.RrNext.UeId = Station.Users(iUser + 1);
						Station.RrNext.Index = iUser + 1;
					end
					% in both cases, stop the loop
					iUser = sz +1;
				end
			end

	end


end
