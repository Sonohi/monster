function [sym, symInfo] = createSymbols(station, user, cwd, cwdInfo, param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 	CREATE SYMBOLS is used to generate the arrays of complex symbols 					 %
% 																																						 %
%   Function fingerprint                                                       %
%   station							-> 	the eNodeB processing the codeword                 %
%   user								->	the UE for this codeword                           %
%   cwd    							->	codeword to be processed                           %
%   cwdInfo							->	codeword info for processing                       %
%   param.maxSymSize		->  max size of a list of symbols for padding          %
% 																																						 %
% 	sym									-> symbols padded																			 %
% 	symInfo							-> symbols info for padding info											 %
% 																																						 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% find all the PRBs assigned to this UE to find the most conservative MCS (min)
	sch = station.schedule;
	ixPRBs = find([sch.UEID] == user.UEID);
	listMCS = [sch(ixPRBs).MCS];

	% get the correct parameters for this UE
	[~, mod, ~] = lteMCS(min(listMCS));

	% setup the PDSCH for this UE
	station.PDSCH.Modulation = mod;	% conservative modulation choice from above
	station.PDSCH.PRBSet = ixPRBs;	% set of assigned PRBs

	% extract the codeword from the padded array
	cwdEx(1:cwdInfo.cwdSize) = cwd(1:cwdInfo.cwdSize);

	% Get info and generate symbols
	[pdschIxs, symInfo] = ltePDSCHIndices(station, station.PDSCH, station.PDSCH.PRBSet);
	sym = ltePDSCH(station, station.PDSCH, cwdEx);

	% padding
	symInfo.symSize = length(sym);
	symInfo.indexes = pdschIxs;
	padding(1:param.maxSymSize - symInfo.symSize,1) = -1;
	sym = cat(1, sym, padding);


end
