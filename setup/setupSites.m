function Sites = setupSites (Config, Logger)
	% setupSites - performs the necessary setup for the eNodeB sites in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Sites: Array<Site> simulation eNodeBs class instances
	
	
	% Setup macro
	Logger.log('(SETUP - setupSites) setting up macro sites', 'DBG');
	for iSite = 1:Config.MacroEnb.sitesNumber
		% Retrieve site ID and cells IDs for this site
		siteId = iSite;
		iSiteCells = find([Config.Plot.Layout.MacroCells.SiteID] == siteId);
		siteCellsIds = [Config.Plot.Layout.MacroCells(iSiteCells).CellID];
		sitePosition = [Config.Plot.Layout.MacroCoordinates(iSite,:), Config.MacroEnb.height];
		% Call the site constructor and pass site and cells IDs
		Sites(iSite) = Site(Config, Logger, sitePosition, siteId, 'macro', -1, siteCellsIds);
	end

	if Config.MicroEnb.sitesNumber > 0
		% Micro sites should be created within the macro cells, depending on the number
		totMacroCells = Config.MacroEnb.sitesNumber * Config.MacroEnb.cellsPerSite;
		for iSite = 1:Config.MicroEnb.sitesNumber
			iMacroCell = iSite - floor(iSite/totMacroCells)*totMacroCells;
			if ~iMacroCell
				iMacroCell = totMacroCells;
			end
			macroCell = Config.Plot.Layout.MacroCells(iMacroCell);
			% The microCoordinates is of size Config.MicroEnb.microPosPerMacroCell
			% We need to find how many of the micro sites positions are already used in this macro cell
			% Find cells that have set the macro cell to the current one
			iMicroCellInMacro = 1;
			allCells = [Sites.Cells];
			iCellsInMacro = find([allCells.MacroCellId] == macroCell.CellID);

			if ~isempty(iCellsInMacro)
				iMicroCellInMacro = iMicroCellInMacro + length(iCellsInMacro)/Config.MicroEnb.microPosPerMacroCell;
				% Throw an error if there are more than the allowed number
				if iMicroCellInMacro > Config.MicroEnb.microPosPerMacroCell
					Logger.log("(SETUP - setupSites) exceeded maximum number of allowed micro sites per macro cell", "ERR");
				end
			end
			sitePosition = [macroCell.MicroCoordinates(iMicroCellInMacro, :), Config.MicroEnb.height];
			siteId = iSite + Config.MacroEnb.sitesNumber;
			% Now find IDS for the micro cells that can be created for this micro site
			iSiteCells = find([Config.Plot.Layout.MicroCells.SiteID] == siteId);
			siteCellsIds = [Config.Plot.Layout.MicroCells(iSiteCells).CellID];
			Sites(iSite + Config.MacroEnb.sitesNumber) = Site(Config, Logger, ...
				sitePosition, siteId, 'micro', macroCell.CellID, siteCellsIds);
		end
	end
end
	