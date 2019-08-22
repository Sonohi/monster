function Sites = setupSites (Config, Logger)
	% setupSites - performs the necessary setup for the eNodeB sites in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Sites: Array<Site> simulation eNodeBs class instances
	
	
	% Setup macro
	Logger.log('(SETUP - setupSites) setting up macro sites', 'DBG');
	Sites = arrayfun(@(x) Site(Config, Logger, x, [], 'macro'), 1:Config.MacroEnb.sitesNumber);

	% Setup micro (without arrayfun as we need always the latest list of sites)
	if Config.MicroEnb.sitesNumber > 0 
		for iSite = 1: Config.MicroEnb.sitesNumber
			Sites(iSite + Config.MacroEnb.sitesNumber) = Site(Config, Logger, iSite, Sites, 'micro');
		end
	end
end
	