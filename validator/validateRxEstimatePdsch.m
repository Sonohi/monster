function validateRxEstimatePdsch(rx)

	%   VALIDATE RECEIVER ESTIMATE PDSCH performs valdiation for the Receiver estimatePdsch
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'ReceiverModule'},{'size',[1,1]});
	if isempty(rx.NoiseEst)
		sonohiLog('Receiver has empty parameters for PDSCH estimation', 'ERR');
	end
end
