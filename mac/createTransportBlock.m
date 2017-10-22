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
	enb = struct(Station);
	numPRB = 0;
	avMCS = 0;
	avMOrd = 0;
	qsz = User.Queue.Size;
	sch = enb.Schedule;
	ixPRBs = find([sch.UeId] == User.UeId);
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

	% the transport block is created of a size that matches the allocation that the 
	% PDCSH symbols will have on the grid 
	[~, mod, ~] = lteMCS(avMCS);
	enb.Tx.PDSCH.Modulation = mod;
	enb.Tx.PDSCH.PRBSet = (ixPRBs - 1).';	
	[~,info] = ltePDSCHIndices(enb,enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
	TbInfo.tbSize = info.Gd;
	TbInfo.rateMatch = info.G;
	% the redundacy version (RV) is defaulted to 0
	TbInfo.rv = 0;

	% Now we need to encode the SQN and the HARQ process ID into the TB if retransmissions are enabled
	% We use the first 13 bits for that; the first 10 are the SQN number of this TB, the other 3 are the HARQ PID
	if Param.rtxOn 
		sqn = getSqn(Station, User, 'format', 'b');
		harqPid = getHarqPid(Station, User, sqn, 'outFormat', 'b', 'inFormat', 'b');
		ctrlBits = cat(1, sqn, harqPid);
		tbPayload = randi([0 1], TbInfo.tbSize - length(ctrlBits), 1);
		tb = cat(1, ctrlBits, tbPayload);
	else
		tb = randi([0 1], TbInfo.tbSize, 1);
	end

	% update User queue by reducing the data bits sent
	if qsz <= TbInfo.tbSize
		User.Queue.Size = User.Queue.Size - qsz;
	else
		User.Queue.Size = User.Queue.Size - TbInfo.tbSize;
	end

end
