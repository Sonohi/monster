function Users = setupUsers (Config)
	% setupUsers - performs the necessary setup for the UEs in the simulation
	%	
	% Syntax: Users = setupUsers(Config)
	% Parameters:
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Users: (Array<UserEquipment>) simulation UEs class instances

	monsterLog('(SETUP - setupUsers) setting up UEs', 'NFO');
	numUsers = Config.Ue.number;
	Users = arrayfun(@(x) UserEquipment(Config, x), 1:numUsers);
end
	