function validateRxCalculateThroughput(rx)

	%   VALIDATE RECEIVER CALCULATE THROUGHPUT validated parameters for throughput calculation
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'ReceiverModule'},{'size',[1,1]});
	if (length(rx.TransportBlock) == 0 || length(rx.Crc) == 0)
		sonohiLog('Receiver has empty parameters for Throughput calculation', 'ERR');
	end
end
