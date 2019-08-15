function Station = findStation(cellId, Sites)
	% Returns the EvolvedNoedB handle from the Sites list, based on the cellId
	% 
	% :param cellId: Number the ID of the cell to be found
	% :param Sites: Array<Site> the list of sites
	%
	% :returns Station: EvolvedNodeB handle of the cell found

	allCells = [Sites.Cells];
	iCell = find([allCells.NCellID] == cellId);
	if ~isempty(iCell)
		Station = allCells(iCell);
	else
		error('(FIND STATION) Station not found','ERR');
	end
end