function [alloc] = allocatePRBs(station)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ALLOCATE PRBS is used to return the allocation of PRBs for a schedule 		 %
%                                                                              %
%   Function fingerprint                                                       %
%   station		->  base station struct with current list of associated users    %
%                                                                              %
%   alloc			->  allocation array with: 																			 %
%             		--> UEID	id of the UE scheduled in that slot                %
%									--> MCS 	modulation and coding scheme decided							 %
%									--> mOrd	modulation order as bits/OFDM symbol							 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% reset the allocation
	alloc(1:station.NDLRB) = struct('UEID',0,'MCS',0,'mOrd',0);

	% TODO remove random allocation
	sz = length(station.Users);
	for (ix = 1:station.NDLRB)
		alloc(ix).UEID = station.Users(randi(sz));
		alloc(ix).MCS = randi([1,32]);
		alloc(ix).modOrd = 2*randi([1,3]);
	end
end
