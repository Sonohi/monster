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

	alloc = [];

end
