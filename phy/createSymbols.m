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
	sch = enb.Schedule;
	ixPRBs = find([sch.UeId] == User.UeId);
	listMCS = [sch(ixPRBs).Mcs];

	% get the correct Parameters for this UE
	[~, mod, ~] = lteMCS(min(listMCS));

	% setup the PDSCH for this UE
	enb.Tx.PDSCH.Modulation = mod;	% conservative modulation choice from above
	enb.Tx.PDSCH.PRBSet = (ixPRBs - 1).';	% set of assigned PRBs

	% extract the codeword from the padded array
	cwdEx(1:CwdInfo.cwdSize, 1) = cwd(1:CwdInfo.cwdSize,1);

	% Get info and indexes
	[pdschIxs, SymInfo] = ltePDSCHIndices(enb, enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);

	% before generating the PDSCH, we need to check whether padding is needed based
	% on the available/allocated resources
	if length(cwdEx) < SymInfo.G
		padding(1:SymInfo.G - length(cwdEx), 1) = 0;
		cwdEx = cat(1, cwdEx, padding);
	elseif length(cwdEx) > SymInfo.G % TODO check in which cases this can happen
		cwdEx = cwdEx(1:SymInfo.G);
	end

	% error handling for symbol creation

	try
		sym = ltePDSCH(enb, enb.PDSCH, cwdEx);
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
