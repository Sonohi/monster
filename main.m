% Main entry point for MONSTER

monsterLog('(MAIN) initialising simulation', 'NFO');
% Add setup folder to path
addpath('setup');

% Run setup function and get a configuration object
monsterLog('(MAIN) running simulation setup', 'NFO');
[Config, Stations, Users, Channel, Traffic, Results] = setup();
monsterLog('(MAIN) simulation setup completed', 'NFO');

% Create a simuation object
monsterLog('(MAIN) creating main simulation instance', 'NFO');
Simulation = Monster(Config, Stations, Users, Channel, Traffic, Results);
monsterLog('(MAIN) main simulation instance created', 'NFO');

% Main simulation loop
for iRound = 0:(Config.Runtime.totalRounds - 1)
	Config.Runtime.currentRound = iRound;

	monsterLog(sprintf(...
		'(MAIN) simulation round %i, rounds left %i, time elapsed %f s, time left %f s',....
		iRound, Config.Runtime.totalRounds, Config.Runtime.simTimeElapsed, Config.Runtime.simTimeRemaining), 'NFO');	
	
	Simulation.run();

	monsterLog(sprintf(...
		'(MAIN) completed simulation round %i, rounds left %i, time elapsed %f s, time left %f s',....
		iRound, Config.Runtime.totalRounds, Config.Runtime.simTimeElapsed, Config.Runtime.simTimeRemaining), 'NFO');

	Simulation.collectResults();

	monsterLog('(MAIN) collected simulation round results', 'NFO');

	Simulation.clean();

	monsterLog('(MAIN) cleaned parameters for next round', 'NFO');

	
end

