function Results = setupResults (Config)
	% setupResults - performs the necessary setup for the simulation results
	%	
	% Syntax: Results = setupResults(Config)
	% Parameters:
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Results: (MetricRecorder) simulation metric recorder class instances

	monsterLog('(SETUP - setupResults) setting up results structure', 'NFO');
	% TODO check whether we need to differentiate cases with thr parameters
	Results = MetricRecorder(Config);

end
	