function Sites = setupSites (Config, Logger)
	% setupSites - performs the necessary setup for the eNodeB sites in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Sites: Array<Site> simulation eNodeBs class instances
	
	
	% Setup macro
	Logger.log('(SETUP - setupSites) setting up macro sites', 'DBG');
	rangeA = 1;
	rangeB = Config.MacroEnb.sitesNumber;
	Sites(rangeA:rangeB) = arrayfun(@(x) Site(Config, Logger, x, 'macro', Config.MacroEnb.cellsPerSite), rangeA: rangeB);
	for iSite = rangeA:rangeB
		Sitess(iSite).Position = [Config.Plot.Layout.MacroCoordinates(iSite,:), Config.MacroEnb.height];
	end

	% Setup micro
	if Config.MicroEnb.sitesNumber > 0
		Logger.log('(SETUP - setupStations) setting up micro sites', 'DBG');
		rangeA = Config.MacroEnb.sitesNumber + 1;
		rangeB = Config.MicroEnb.sitesNumber + Config.MacroEnb.sitesNumber;
		Sites(rangeA:rangeB) = arrayfun(@(x) Site(Config, Logger, x, 'micro', Config.MicroEnb.cellsPerSite), rangeA: rangeB);
		ii = 1;
		for iSite = rangeA:rangeB
			Stations(iStation).Position = [Config.Plot.Layout.MicroCoordinates(ii,:), Config.MicroEnb.height];
			ii =+ 1;
		end
	end
end
	