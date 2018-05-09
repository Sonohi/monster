function [symMatrix, SymMatrixInfo] = initSymMatrix(Param)

%   INITIALISE SYMBOLS is used to setup the data structures for PDSCH symbols
%
%   Function fingerprint
%   Param.numUsers   		->  number of UEs
%   Param.numMacro   		->  number of macro eNodeBs
%   Param.numMicro   		->  number of micro eNodeBs
% 	Param.numPico				-> 	number of pico eNodeBs
%   Param.maxSymSize		->  max size of a word of symbols in LTE
%
%   symMatrix          	->  symbols storing structure
%   SymMatrixInfo	    	->  symbols info storing structure


	symMatrix(1:Param.numEnodeBs, 1:Param.numUsers, 1:Param.maxSymSize) = 0;
  SymMatrixInfo(1:Param.numEnodeBs + Param.numPico, 1:Param.numUsers ) = struct(...
		'G', 0, 'Gd', 0, 'symSize', 0, 'indexes',[] , 'pdschIxs', []);

end
