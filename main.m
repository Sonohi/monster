% Main entry point for MONSTER

% Disable cast to struct warnings
w = warning ('off','all');

monsterLog('(MAIN) initialising simulation', 'NFO');

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
	Simulation.setupRound(iRound);

	monsterLog(sprintf('(MAIN) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
		Simulation.Config.Runtime.remainingTime ), 'NFO');	
	
	Simulation.run();

	monsterLog(sprintf('(MAIN) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

	Simulation.collectResults();

	monsterLog('(MAIN) collected simulation round results', 'NFO');

	Simulation.clean();

	monsterLog('(MAIN) cleaned parameters for next round', 'NFO');
end

