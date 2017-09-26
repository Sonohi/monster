function [procs] = harqTxBulk(transmitter, receiver, Param, tnow)

% 	HARQ TX BULK is used to create a bulk of HARQ transmitters
%
%   Function fingerprint
%   transmitter		-> 	the id of the transmitter node
%   Param					->	the simulation parameters
%
% 	procs					-> harq transmitter processes


	for ix = 1:Param.harq.proc
		procs(ix) = HarqTx(transmitter, receiver, ix, [], tnow);
	end
	
end
