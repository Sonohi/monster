function enbSyms = extractStationSyms(Station, ix, syms, Param)

% 	EXTRACT STATION SYMBOLS is used to extract all the symbols of one eNodeB
%
%   Function fingerprint
%   Station							-> 	the eNodeB processing the codeword
%   ix									->	index of the station
%   syms  							->	overall matrix with all teh symbols
%   Param.maxSymSize		->	max size of a list of symbols for padding
%
% 	enbSyms							->	collated station symbols

	% extract the unique UE IDs from the schedule
	uniqueIds = extractUniqueIds([Station.ScheduleDL.UeId]);

	temp = [];
	% loop through the overall matrix of symbols and concatenate
	for iUser = 1:length(uniqueIds)
		a(1:Param.maxSymSize, 1) = syms(ix, uniqueIds(iUser), :);
		temp = cat(1, temp, a);
	end

	% as a last step, remove the zeros and return
	enbSyms = removePadding(temp);
end
