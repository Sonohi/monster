function [Station] = schedule(Station, Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ALLOCATE PRBS is used to return the allocation of PRBs for a schedule 		 %
%                                                                              %
%   Function fingerprint                                                       %
%   Station					->  base Station																				   %
%   Param.prbSym		->  number of OFDM symbols per PRB											   %
%                                                                              %
%   Station		->  station with allocation array with: 												 %
%             		--> ueId		id of the UE scheduled in that slot              %
%									--> mcs 		modulation and coding scheme decided						 %
%									--> modOrd	modulation order as bits/OFDM symbol						 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% reset the allocation
	Station.Schedule(1:Station.NDLRB) = struct('ueId',0,'mcs',0,'modOrd',0);
	sz = length(Station.Users);

	switch (Param.scheduling)
		case 'roundRobin'
			if (Station.rrNext.ueId == 0)
				Station.rrNext.ueId = Station.Users(1).ueId;
				Station.rrNext.index = 1;
			end

			maxRounds = sz;
			prbsAv = Station.NDLRB;
			iUser = Station.rrNext.index;
			while (iUser <= sz && maxRounds > 0)
				User = Station.Users(iUser);
				if (prbsAv > 0)
					if (~User.scheduled && User.queue.size > 0)
						modOrd = cqi2modOrd(User.wCqi);
						prbsNeed = ceil(User.queue.size/(modOrd * Param.prbSym));
						prbsSch = 0;
						if (prbsNeed >= prbsAv)
							prbsSch = prbsAv;
						else
							prbsSch = prbsNeed;
						end
						prbsAv = prbsAv - prbsSch;
						Station.Users(iUser).scheduled = true;
						iUser = iUser + 1;
						% write to schedule struct
						for (iPrb = 1:Station.NDLRB)
							if (Station.Schedule(iPrb).ueId == 0)
								mcs = cqi2mcs(User.wCqi);
								for (iSch = 1:prbsSch)
									Station.Schedule(iPrb + iSch) = struct('ueId', User.ueId,...
										'mcs', mcs, 'modOrd', modOrd);
								end
								break;
							end
						end
					end
					maxRounds = maxRounds -1;
				else
					% Keep track of the next user to be scheduled in the next round
					if (iUser + 1 > sz || Station.Users(iUser + 1).ueId == 0)
						Station.rrNext.ueId = Station.Users(1).ueId;
						Station.rrNext.index = 1;
					else
						Station.rrNext.ueId = Station.Users(iUser + 1).ueId;
						Station.rrNext.index = iUser + 1;
					end
					% in both cases, stop the loop
					iUser = sz +1;
				end
			end

		case 'random'
			for (ix = 1:Station.NDLRB)
				Station.Schedule(ix).ueId = Station.Users(randi(sz));
				Station.Schedule(ix).mcs = randi([1,28]);
				Station.Schedule(ix).modOrd = 2*randi([1,3]);
			end

	end


end
