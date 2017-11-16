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
	arqRtxInfo = Station.Rlc.ArqTxBuffers(iUserRlc).getRetransmissionState();

	% MAC queues check
	iUserMac = find([Station.Mac.HarqTxProcesses.rxId] == UeId);
	harqRtxInfo = Station.Mac.HarqTxProcesses(iUserMac).getRetransmissionState();

	% HARQ retransmissions have the priority 
	if harqRtxInfo.flag
		rtxInfo.proto = 1;
		rtxInfo.identifier = harqRtxInfo.procIndex;
		rtxInfo.iUser = iUserMac;
	elseif arqRtxInfo.flag
		rtxInfo.proto = 2;
		rtxInfo.identifier = arqRtxInfo.bufferIndex;
		rtxInfo.iUser = iUserRlc;
	else
		rtxInfo.proto = 0;
		rtxInfo.identifier = [];
	end

end