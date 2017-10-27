function [Station, User] = createTransportBlock(Station, User, Param, timeNow)

%   CREATE TRANSPORT BLOCK  is used to return the TB the scheduling round
%
%   Function fingerprint
%   Station		->  the base station serving the User
%   User      ->  the User allocated in the subframe
%   Param  		->  simulation parameters
% 	timeNow		->	current simulation time
%
%   User	     				->  the updated UE object
%   Station    				->  the updated eNodeB object

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
	% We use the first 13 bits for that; the first 3 are the HARQ PID. the other 10 are the SQN
	newTb = false;
	if Param.rtxOn 
		[Station, sqn] = getSqn(Station, User.UeId, 'outFormat', 'b');
		[Station, harqPid, newTb] = getHarqPid(Station, User, sqn, 'outFormat', 'b', 'inFormat', 'b');
		ctrlBits = cat(1, harqPid, sqn);
		tbPayload = randi([0 1], TbInfo.tbSize - length(ctrlBits), 1);
		tb = cat(1, ctrlBits, tbPayload);
		if newTb
			Station = setHarqTb(Station, User, harqPid, timeNow, tb);
		end
	else
		tb = randi([0 1], TbInfo.tbSize, 1);
	end

	% update User queue by reducing the data bits sent
	if (Param.rtxOn && newTb) || ~Param.rtxOn
		if qsz <= TbInfo.tbSize
			User.Queue.Size = User.Queue.Size - qsz;
		else
			User.Queue.Size = User.Queue.Size - TbInfo.tbSize;
		end
	end
	

	User.TransportBlock = tb;
	User.TransportBlockInfo = TbInfo;

end
