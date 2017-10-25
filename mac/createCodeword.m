function User = createCodeword(User, Param)

%   CREATE CODEWORD  is used to complete the DL-SCH processing to a codeword
%
%   Function fingerprint
%   User        				-> the UE object  
%   Param.maxCwdSize    ->  max codeword size for padding
%
%   User  	  					->  the updated UE object

  % perform CRC encoding with 24A poly
	% TB has to be a vector for the LTE library, extract the actual
  encTB = lteCRCEncode(User.TransportBlock, '24A');

  % create code block segments
  cbs = lteCodeBlockSegment(encTB);

  % turbo-encoding of cbs
  turboEncCbs = lteTurboEncode(cbs);

  % finally rate match and return codeword
  cwd = lteRateMatchTurbo(turboEncCbs, User.TransportBlockInfo.rateMatch, ...
    User.TransportBlockInfo.rv);

	CwdInfo.cwdSize = length(cwd);

  User.Codeword = cwd;
  User.CodewordInfo = CwdInfo;
end
