function [tb, TbInfo] = createTransportBlock(Station, User, Param)

%   CREATE TRANSPORT BLOCK  is used to return the TB the scheduling round
%
%   Function fingerprint
%   Station        		->  the base station serving the User
%   User        			->  the User allocated in the subframe
%   sch  							->  schedule for staion
%   Param.maxTBSize  	->  max size of a TB in LTE
%
%   tb	      				->  padded transport block
%   TbInfo 						->  actual size and rate matching

	% get a single MCS and modulation order across all the PRBs assigned to a UE
	numPRB = 0;
	avMCS = 0;
	avMOrd = 0;
	qsz = User.Queue.Size;
	sch = Station.Schedule;
	for (iPrb = 1:length(sch))
		if (sch(iPrb).UeId == User.UeId)
			numPRB = numPRB + 1;
			avMCS = avMCS + sch(iPrb).Mcs;
			avMOrd = avMOrd + sch(iPrb).ModOrd;
		end
	end

	% this shouldn't happen as we always schedule at least 1 PRB per User,
	% otherwise it should not be in the list, but never know
	if (numPRB ~= 0)
		avMCS = round(avMCS/numPRB);
		avMOrd = round(avMOrd/numPRB);
	end

	% the transport block is created of a size that is the minimum between the
	% traffic queue size and the maximum size of the uncoded transport block
	% the redundacy version (RV) is defaulted to 0
	TbInfo.tbSize = min(qsz, lteTBS(numPRB, avMCS));	
	TbInfo.rateMatch = lteTBS(numPRB, avMCS);
	TbInfo.rv = 0;

	tb = randi([0 1], TbInfo.tbSize, 1);
	% pad the rest of the TB for storage with -1
	padding(1:Param.maxTbSize - TbInfo.tbSize, 1) = -1;
	% concatenate the padding
	tb = cat(1, tb, padding);

	% update User queue by reducing the bits sent
	User.Queue.Size = User.Queue.Size - TbInfo.tbSize;

end
