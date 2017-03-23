function [cwd] = createCodeword(tb, rv, rm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CODEWORD  is used to complete the DL-SCH processing to a codeword	 %
%                                                                              %
%   Function fingerprint                                                       %
%   tb        ->  transport block                                              %
%   rv        ->  redundacy version                                            %
%   rm        ->  rate matching                                                %
%                                                                              %
%   cwd	      ->  codeword                                                     %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % perform CRC encoding with 24A poly
  encTB = lteCRCEncode(tb, '24A');

  % create code block segments
  cbs = lteCodeBlockSegment(encTB);

  % turbo-encoding of cbs
  turboEncCbs = lteTurboEncode(cbs);

  % finally rate match and return codeword
  cwd = lteRateMatchTurbo(turboEncCbs, rm, rv);

end
