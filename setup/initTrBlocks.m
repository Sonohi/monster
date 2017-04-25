function [tb, info] = initTrBlocks(param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   INITIALISE TRANSPORT BLOCKS is used to setup the data structures for TBs   %
%                                                                              %
%   Function fingerprint                                                       %
%   param.numUsers   ->  number of UEs                                         %
%   param.numMacro   ->  number of macro eNodeBs                               %
%   param.numMicro   ->  number of micro eNodeBs                               %
%   param.maxTBSize  ->  max size of a TB in LTE                               %
%                                                                              %
%   tb	             ->  tb storing structure                                  %
%   info	           ->  tb info storing structure                             %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	tb(1:param.numMacro + param.numMicro, 1:param.numUsers, 1:param.maxTBSize) = 0;
  info(1:param.numMacro + param.numMicro, 1:param.numUsers ) = ...
		struct('tbSize', 0, 'rateMatch', 0, 'rv', 0);

end
