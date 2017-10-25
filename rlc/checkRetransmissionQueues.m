function info = checkRetransmissionQueues(Station, UeId)

%   CHECK RETRANSMISSION QUEUES returns the status of the RLC and MAC queues
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   UeID      	->  the UE ID
%
%   info				->  the info struct with the queue stats

	% RLC queue check
	iUser = find([Station.Rlc.ArqTxBuffers.receiver] == UeId);
	arqInfo = getRetransmissionState(Station.Rlc.ArqTxBuffers(iUser));

	% MAC queues check
	iUser = find([Station.Mac.HarqTxProcesses.receiver] == UeId);
	harqInfo = getRetransmissionState(Station.Mac.HarqTxProcesses(iUser));

	


end