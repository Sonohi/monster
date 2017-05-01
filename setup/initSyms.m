function [syms, info] = initSyms(param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   INITIALISE SYMBOLS is used to setup the data structures for PDSCH symbols  %
%                                                                              %
%   Function fingerprint                                                       %
%   param.numUsers   		->  number of UEs                                      %
%   param.numMacro   		->  number of macro eNodeBs                            %
%   param.numMicro   		->  number of micro eNodeBs                            %
%   param.maxSymSize		->  max size of a word of symbols in LTE               %
%                                                                              %
%   syms             		->  tb storing structure                               %
%   info	           		->  tb info storing structure                          %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	syms(1:param.numMacro + param.numMicro, 1:param.numUsers, 1:param.maxSymSize) = 0;
  info(1:param.numMacro + param.numMicro, 1:param.numUsers ) = struct('symSize',0);

end
