function [Station] = allocatePRBs(Station, Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ALLOCATE PRBS is used to return the allocation of PRBs for a schedule 		 %
%                                                                              %
%   Function fingerprint                                                       %
%   Station		->  base Station struct with current list of associated users    %
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
		case 'roundrobin'
		case 'random'
			for (ix = 1:Station.NDLRB)
				Station.Schedule(ix).ueId = Station.Users(randi(sz));
				Station.Schedule(ix).mcs = randi([1,28]);
				Station.Schedule(ix).modOrd = 2*randi([1,3]);
			end
		case 'proportionalfair'
		case 'supermegacool'
	end


end
