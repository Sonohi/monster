function cqi = decodeCqi(pucchBits)

%   DECODE CQI is used to decode the cqi bits received in the PUCCH to decimal
%
%   Function fingerprint
%   pucchBits		->  PUCCH 2 or 3 bits
%
%   cqi	  			->  decoded CQI in decimal

	cqiBits = pucchBits(12:16,1);
	cqi = bi2de(cqiBits', 'left-msb');

end