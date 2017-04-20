function [alloc] = allocatePRBs(node)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ALLOCATE PRBS is used to return the allocation of PRBs for a schedule 		 %
%                                                                              %
%   Function fingerprint                                                       %
%   node  ->  the base station struct with current list of associated users    %
%                                                                              %
%   alloc	->  allocation array as set of structs where each entry corresponds: %
%             --> UEID	id of the UE scheduled in that slot                    %
%							--> MCS 	modulation and coding scheme decided									 %
%							--> mOrd	modulation order as bits/OFDM symbol									 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% reset the allocation

	alloc(1:node.NDLRB) = struct('UEID',0,'MCS',0,'mOrd',0);
	% TODO remove random allocation
	for (ix = 1:node.NDLRB)
		alloc(ix).UEID = randi([1,15]);
		alloc(ix).MCS = randi([1,32]);
		alloc(ix).modOrd = 2*randi([1,3]);
	end
end
