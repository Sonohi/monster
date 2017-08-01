function validateRxEstimateChannel(rx)

	%   VALIDATE RECEIVER ESTIMATE CHANNEL performs valdiation for the Receiver estimateChannel
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'ReceiverModule'},{'size',[1,1]});
	if sum(rx.RxSubFrame == 0)
		sonohiLog('Receiver has empty parameters for estimating the channel', 'ERR');
	end
end
