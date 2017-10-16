function [buffers] = rlcBufferBulk(Param)

%   RLC BUFFER BULK is used to create a bulk of RLC buffers
%
%   Function fingerprint
%   Param			->  simulation parameters
%
%   buffers		->  RLC buffers

	for ix = 1:Param.numUsers
		buffers(ix) = RlcTxBuffer(Param);
	end

end
