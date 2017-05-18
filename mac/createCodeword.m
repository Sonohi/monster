function [cwd, CwdInfo] = createCodeword(tb, TbInfo, Param)

%   CREATE CODEWORD  is used to complete the DL-SCH processing to a codeword
%
%   Function fingerprint
%   tb        					->  transport block
%   TbInfo    					->  encoding info with RV, rate matching and size
%   Param.maxCwdSize    ->  max codeword size for padding
%
%   cwd	      					->  codeword
%   CwdInfo	  					->  codeword info struct akin to TbInfo

  % perform CRC encoding with 24A poly
	% TB has to be a vector for the LTE library, extract the actual
  encTB = lteCRCEncode(tb(1:TbInfo.rateMatch,1), '24A');

  % create code block segments
  cbs = lteCodeBlockSegment(encTB);

  % turbo-encoding of cbs
  turboEncCbs = lteTurboEncode(cbs);

  % finally rate match and return codeword
  cwd = lteRateMatchTurbo(turboEncCbs, TbInfo.rateMatch, TbInfo.rv);

	% padding
	CwdInfo.cwdSize = length(cwd);
	padding(1:Param.maxCwdSize - CwdInfo.cwdSize, 1) = -1;
	cwd = cat(1, cwd, padding);

end
