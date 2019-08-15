function validateConfiguration(Config, Logger)
	% Validates the configuration of the simulation 
	%
	% :param Config: MonsterConfig instance including scenario-specific configurations
	% :param Logger: MonsterLog instance
	%

	% Assert macro eNodeB configuration
	if strcmp(Config.MacroEnb.antennaType, 'sectorised')
		errMsg = "(CONFIG VALIDATION) invalid value of cellsPerSite for macro eNodeB with sectorised antenna type. Only 1 and 3 sectors are allowed";
		assert(Config.MacroEnb.cellsPerSite == 1 || Config.MacroEnb.cellsPerSite == 3, errMsg)
	end

	% Assert macro eNodeB configuration
	if strcmp(Config.MicroEnb.antennaType, 'sectorised')
		errMsg = "(CONFIG VALIDATION) invalid value of cellsPerSite for micro eNodeB with sectorised antenna type. Only 1 and 3 sectors are allowed";
		assert(Config.MicroEnb.cellsPerSite == 1 || Config.MicroEnb.cellsPerSite == 3, errMsg)
	end

	% Valid configuration
	Logger.log("(CONFIG VALIDATION) simulation configuration is valid", 'DBG');
end