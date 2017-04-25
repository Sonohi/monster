function [cwd, info] = initCwds(param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   INITIALISE CODEWORD is used to setup the data structures for TBs   %
%                                                                              %
%   Function fingerprint                                                       %
%   param.numUsers   		->  number of UEs                                      %
%   param.numMacro   		->  number of macro eNodeBs                            %
%   param.numMicro   		->  number of micro eNodeBs                            %
%   param.maxCwdSize		->  max size of a TB in LTE                            %
%                                                                              %
%   cwd	             		->  tb storing structure                               %
%   info	           		->  tb info storing structure                          %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	cwd(1:param.numMacro + param.numMicro, 1:param.numUsers, 1:param.maxCwdSize) = 0;
  info(1:param.numMacro + param.numMicro, 1:param.numUsers ) = struct('cwdSize',0);

end
