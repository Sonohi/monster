function [sym, SymInfo] = createSymbols(Station, User, cwd, CwdInfo, Param)

% 	CREATE SYMBOLS is used to generate the arrays of complex symbols
%
%   Function fingerprint
%   Station							-> 	the eNodeB processing the codeword
%   User								->	the UE for this codeword
%   cwd    							->	codeword to be processed
%   CwdInfo							->	codeword info for processing
%   Param.maxSymSize		->  max size of a list of symbols for padding
%
% 	sym									-> symbols padded
% 	SymInfo							-> symbols info for padding info

	% find all the PRBs assigned to this UE to find the most conservative MCS (min)
	sch = Station.Schedule;
	ixPRBs = find([sch.ueId] == User.ueId);
	listMCS = [sch(ixPRBs).mcs];

	% get the correct Parameters for this UE
	[~, mod, ~] = lteMCS(min(listMCS));

	% setup the PDSCH for this UE
	Station.PDSCH.Modulation = mod;	% conservative modulation choice from above
	Station.PDSCH.PRBSet = (ixPRBs - 1).';	% set of assigned PRBs

	% extract the codeword from the padded array
	cwdEx(1:CwdInfo.cwdSize, 1) = cwd(1:CwdInfo.cwdSize,1);

	% Get info and generate symbols
	[pdschIxs, SymInfo] = ltePDSCHIndices(Station, Station.PDSCH, Station.PDSCH.PRBSet);
	% error handling for symbol creation
	% TODO try finding out errror root cause, e.g. invald TB size?
	try
		sym = ltePDSCH(Station, Station.PDSCH, cwdEx);
	catch ME
		fSpec = 'symbols generation failed for codeword with length %i\n';
		fprintf(fSpec, length(cwdEx));
		sym = [];
	end


	% padding
	SymInfo.symSize = length(sym);
	SymInfo.pdschIxs = pdschIxs;
	SymInfo.indexes = ixPRBs;
	padding(1:Param.maxSymSize - SymInfo.symSize,1) = -1;
	sym = cat(1, sym, padding);


end
