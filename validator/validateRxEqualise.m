function validateRxEqualise(rx)

	%   VALIDATE RECEIVER EQUALISE performs valdiation for the Receiver equalise
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'ReceiverModule'},{'size',[1,1]});
	%if (sum(rx.Subframe) == 0 || sum(rx.EstChannelGrid) == 0 || sum(rx.NoiseEst) == 0)
	%	sonohiLog('Receiver has empty parameters for equalisation', 'ERR');
	%end
end
