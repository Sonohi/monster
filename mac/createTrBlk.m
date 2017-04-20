function [trBlk, info] = createTrBlk(node, user, sch, qsz, param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE TRANSPORT BLOCK  is used to return the TB the scheduling round			 %
%                                                                              %
%   Function fingerprint                                                       %
%   node        			->  the base station serving the user                    %
%   user        			->  the user allocated in the subframe                   %
%   sch  							->  schedule for staion                                  %
%   qsz  							->  traffic queue size                                   %
%   param.maxTBSize  	->  max size of a TB in LTE                              %
%                                                                              %
%   trBlk	      			->  padded transport block 				                       %
%   info 						  ->  actual size and rate matching                        %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% get a single MCS and modulation order across all the PRBs assigned to a UE
	numPRB = 0;
	avMCS = 0;
	avMOrd = 0;
	for (ix = 1:length(sch))
		if (sch(ix).UEID == user.UEID)
			numPRB = numPRB + 1;
			avMCS = avMCS + sch(ix).MCS;
			avMOrd = avMOrd + sch(ix).mOrd;
		end
	end

	% this shouldn't happen as we always schedule at least 1 PRB per user,
	% otherwise it should not be in the list, but never know
	if (numPRB ~= 0)
		avMCS = round(avMCS/numPRB);
		avMOrd = round(avMOrd/numPRB);
	end


	% the transport block is created of a size that is the minimum between the
	% traffic queue size and the maximum size of the uncoded transport block
	info.tbSize = min(qsz, lteTBS(numPRB, avMCS));
	info.rateMatch = lteTBS(numPRB, avMCS);

	trBlk = randi([0 1], info.tbSize, 1);
	% pad the rest of the TB for storage with -1
	padding(1:param.maxTBSize - info.tbSize, 1) = -1;
	% concatenate the padding
	trBlk = cat(1, trBlk, padding);

end
