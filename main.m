% Main entry point for MONSTER

monsterLog('(MAIN) initialising simulation', 'NFO');
% Add setup folder to path
addpath('setup');

% Run setup function and get a configuration object
monsterLog('(MAIN) running simulation setup', 'NFO');
[Config, Stations, Users, Channel, Traffic] = setup();
monsterLog('(MAIN) simulation setup completed', 'NFO');

% Create a simuation object
monsterLog('(MAIN) creating main simulation instance', 'NFO');
Simulation = Monster(Config, Stations, Users, Channel, Traffic);
monsterLog('(MAIN) main simulation instance created', 'NFO');



