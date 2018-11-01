function [tbMatrix, TbMatrixInfo] = initTbMatrix(Param)

%   INITIALISE TRANSPORT BLOCKS is used to setup the data structures for TBs
%
%   Function fingerprint
%   Param.numUsers   ->  number of UEs
%   Param.numMacro   ->  number of macro eNodeBs
%   Param.numMicro   ->  number of micro eNodeBs
% 	Param.numPico		 ->  number of pico eNodeBs

%   Param.maxTBSize  ->  max size of a TB in LTE
%
%   tbMatrix	       ->  TB storing structure
%   TbMatrixInfo	   ->  TB info storing structure


	tbMatrix(1:Param.numEnodeBs, 1:Param.numUsers, 1:Param.maxTbSize) = 0;
  TbMatrixInfo(1:Param.numEnodeBs, 1:Param.numUsers ) = ...
		struct('tbSize', 0, 'rateMatch', 0, 'rv', 0);

end
