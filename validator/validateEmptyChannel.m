function validateEmptyChannel(Channel)

	%   VALIDATE Empty Channel is a simple utility to validate that the channel is
	%   empty and reset
	%
	%   Function fingerprint
	%   Channel		->  test

	validateattributes(Channel,{'ChBulk_v2'},{'size',[1,1]});
  validateattributes(Channel.eHATA,{'double'},{'empty'});
  validateattributes(Channel.WINNER,{'double'},{'empty'});
end
