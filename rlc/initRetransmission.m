function Station = initRetransmission(Station, rtxInfo)

%   INITIALISE RETRANSMISSION is used to start the correct process at ARQ or HARQ
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   rtxInfo     ->  rtxInfo struct with details about the type of retransmission
%
%   Station			->  the updated eNodeB object

	switch rtxInfo.proto
	case 1
		Station.Mac.HarqTxProcesses(rtxInfo.iUser) = ...
			setRetransmissionState(Station.Mac.HarqTxProcesses(rtxInfo(iUser), rtxInfo.identifier));
	case 2
		Station.Rlc.ArqTxBuffers(rtxInfo.iUser) = ...
			setRetransmissionState(Station.Rlc.ArqTxBuffers(rtxInfo.iUser), rtxInfo.identifier);
	end

end