function [buffers] = arqTxBulk(Param, txId, rxList, timeNow)

%   RLC BUFFER BULK is used to create a bulk of RLC buffers
%
%   Function fingerprint
%   Param			->  simulation parameters
%		txId			-> the id of the transmitting node
% 	rxList		-> the list of receivers
% 	timeNow		-> the current simulation time
%
%   buffers		->  RLC buffers

	for iRx = 1:length(rxList)
		buffers(ix) = ArqTx(Param, txId, rxList(iRx), timeNow);
	end

end
