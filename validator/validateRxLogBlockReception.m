function validateRxLogBlockReception(rx)

	%   VALIDATE RECEIVER LOG BLOCK RECEPTION validated parameters for block logging
	%
	%   Function fingerprint
	%   rx		->  test

	validateattributes(rx,{'UEReceiverModule'},{'size',[1,1]});
	if (length(rx.TransportBlock) == 0 || length(rx.Crc) == 0)
		sonohiLog('Receiver has empty parameters for BLER calculation', 'ERR');
	end
end
