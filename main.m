% Main entry point for MONSTER

% Disable cast to struct warnings
w = warning ('off','all');

% Create a simulation config object
Config = MonsterConfig();

% Create a logger instance
Logger = MonsterLog(Config);
Logger.log('(MAIN) configured simulations and started initialisation', 'NFO');


% Create a simuation object
Logger.log('(MAIN) creating main simulation instance', 'NFO');
Simulation = Monster(Config, Logger);
Simulation.Logger.log('(MAIN) main simulation instance created', 'NFO');

% Main simulation loop
for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);

	Simulation.Logger.log(sprintf('(MAIN) simulation round %i, time elapsed %f s, time left %f s',...
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.currentTime, ...
		Simulation.Config.Runtime.remainingTime ), 'NFO');	
	
	Simulation.run();

	Simulation.Logger.log(sprintf('(MAIN) completed simulation round %i. %i rounds left' ,....
		Simulation.Config.Runtime.currentRound, Simulation.Config.Runtime.remainingRounds), 'NFO');

	Simulation.collectResults();

	Simulation.Logger.log('(MAIN) collected simulation round results', 'NFO');

	Simulation.clean();

	if iRound ~= Config.Runtime.totalRounds - 1
		Simulation.Logger.log('(MAIN) cleaned parameters for next round', 'NFO');
	else
		Simulation.Logger.log('(MAIN) simulation completed', 'NFO');
	end
end

