function [cwdMatrix, CwdMatrixInfo] = initCwdMatrix(Param)

%   INITIALISE CODEWORD MATRIX is used to setup the data structures for cwds
%
%   Function fingerprint
%   Param.numUsers   		->  number of UEs
%   Param.numMacro   		->  number of macro eNodeBs
%   Param.numMicro   		->  number of micro eNodeBs
%   Param.numPico   		->  number of pico eNodeBs
%   Param.maxCwdSize		->  max size of a TB in LTE
%
%   cwdMatrix	          ->  tb storing structure
%   CwdMatrixInfo	    	->  tb info storing structure

	cwdMatrix(1:Param.numEnodeBs, 1:Param.numUsers, 1:Param.maxCwdSize) = 0;
  CwdMatrixInfo(1:Param.numEnodeBs, 1:Param.numUsers ) = struct('cwdSize',0);

end
