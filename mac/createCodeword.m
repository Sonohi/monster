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
  encTB = lteCRCEncode(tb, '24A');

  % create code block segments
  cbs = lteCodeBlockSegment(encTB);

  % turbo-encoding of cbs
  turboEncCbs = lteTurboEncode(cbs);

  % finally rate match and return codeword
  cwd = lteRateMatchTurbo(turboEncCbs, TbInfo.rateMatch, TbInfo.rv);

	CwdInfo.cwdSize = length(cwd);
end
