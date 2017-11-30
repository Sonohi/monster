function validateRxEqualise(rx)

	%   VALIDATE RECEIVER EQUALISE performs valdiation for the Receiver equalise
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'ueReceiverModule'},{'size',[1,1]});
	if (isempty(rx.Subframe) || isempty(rx.EstChannelGrid) || isempty(rx.NoiseEst))
		sonohiLog('Receiver has empty parameters for equalisation', 'ERR');
	end
end
