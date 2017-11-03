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

	% cast eNodeB object to struct for the processing
	enb = struct(Station);
	% find all the PRBs assigned to this UE to find the most conservative MCS (min)
	sch = enb.ScheduleDL;
	ixPRBs = find([sch.UeId] == User.UeId);
	listMCS = [sch(ixPRBs).Mcs];

	% get the correct Parameters for this UE
	[~, mod, ~] = lteMCS(min(listMCS));

	% setup the PDSCH for this UE
	enb.Tx.PDSCH.Modulation = mod;	% conservative modulation choice from above
	enb.Tx.PDSCH.PRBSet = (ixPRBs - 1).';	% set of assigned PRBs

	% Get info and indexes
	[pdschIxs, SymInfo] = ltePDSCHIndices(enb, enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
	
	if length(cwd) ~= SymInfo.G
		% In this case seomthing went wrong with the rate maching and in the
		% creation of the codeword, so we need to flag it
		sonohilog('Something went wrong in the codeword creation and rate matching. Size mismatch','ERR');
	end

	% error handling for symbol creation
	try
		sym = ltePDSCH(enb, enb.Tx.PDSCH, cwd);
	catch ME
		fSpec = 'symbols generation failed for codeword with length %i\n';
		s=sprintf(fSpec, length(cwdEx));
    sonohilog(s,'WRN')
		sym = [];
	end

	% padding
	SymInfo.symSize = length(sym);
	SymInfo.pdschIxs = pdschIxs;
	SymInfo.indexes = ixPRBs;
	padding(1:Param.maxSymSize - SymInfo.symSize,1) = -1;
	sym = cat(1, sym, padding);
end
