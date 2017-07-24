function validateChannel(Channel)

	%   VALIDATE Channel is a simple utility to validate the channel
	%
	%   Function fingerprint
	%   Channel		->  test

	validateattributes(Channel,{'ChBulk_v2'},{'size',[1,1]});
end
