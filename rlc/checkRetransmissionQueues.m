function rtxInfo = checkRetransmissionQueues(Station, UeId)

%   CHECK RETRANSMISSION QUEUES returns the status of the RLC and MAC queues
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   UeID      	->  the UE ID
%
%   rtxInfo			->  the rtxInfo struct with the queue stats

	% RLC queue check
	iUserRlc = find([Station.Rlc.ArqTxBuffers.rxId] == UeId);
	arqrtxInfo = getRetransmissionState(Station.Rlc.ArqTxBuffers(iUserRlc));

	% MAC queues check
	iUserMac = find([Station.Mac.HarqTxProcesses.rxId] == UeId);
	harqrtxInfo = getRetransmissionState(Station.Mac.HarqTxProcesses(iUserMac));

	% HARQ retransmissions have the priority 
	if harqrtxInfo.flag
		rtxInfo.proto = 1;
		rtxInfo.identifier = procId;
		rtxInfo.iUser = iUserMac;
	elseif arqrtxInfo.flag
		rtxInfo.proto = 2;
		rtxInfo.identifier = arqrtxInfo.bufferIndex;
		rtxInfo.iUser = iUserRlc;
	else
		rtxInfo.proto = 0;
		rtxInfo.identifier = [];
	end

end