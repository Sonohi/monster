function [cwd, cwdInfo] = createCodeword(tb, tbInfo, param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CODEWORD  is used to complete the DL-SCH processing to a codeword	 %
%                                                                              %
%   Function fingerprint                                                       %
%   tb        					->  transport block                                    %
%   tbInfo    					->  encoding info with RV, rate matching and size      %
%   param.maxCwdSize    ->  max codeword size for padding						           %
%                                                                              %
%   cwd	      					->  codeword                                           %
%   cwdInfo	  					->  codeword info struct akin to tbInfo                %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % perform CRC encoding with 24A poly
	% TB has to be a vector for the LTE library, extract the actual
  encTB = lteCRCEncode(tb(1,1:tbInfo.rateMatch), '24A');

  % create code block segments
  cbs = lteCodeBlockSegment(encTB);

  % turbo-encoding of cbs
  turboEncCbs = lteTurboEncode(cbs);

  % finally rate match and return codeword
  cwd = lteRateMatchTurbo(turboEncCbs, tbInfo.rateMatch, tbInfo.rv);

	% padding
	cwdInfo.cwdSize = length(cwd);
	padding(1:param.maxCwdSize - cwdInfo.cwdSize, 1) = -1;
	cwd = cat(1, cwd, padding);

end
