function Results = setupResults (Config, Logger)
	% setupResults - performs the necessary setup for the simulation results
	%	
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	% :returns Results: MetricRecorder simulation metric recorder class instances

	Logger.log('(SETUP - setupResults) setting up results structure', 'DBG');
	% TODO check whether we need to differentiate cases with thr parameters
	Results = MetricRecorder(Config);

end
	