function Stations = getStations(Sites)
	% getStations returns all the eNodeB stations found in the array of Sites
	%
	% :param Sites: Array<Site> array of sites
	%
	% :returns Stations: Array<EvolvedNodeB> array of eNodeBs

	Stations = [Sites.Cells];
end