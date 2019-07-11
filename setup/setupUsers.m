function Users = setupUsers (Config, Logger)
	% setupUsers - performs the necessary setup for the UEs in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	%	:param Logger: MonsterLog instance 
	% :returns Users: Array<UserEquipment> simulation UEs class instances

	Logger.log('(SETUP - setupUsers) setting up UEs', 'DBG');
	numUsers = Config.Ue.number;
	Users = arrayfun(@(x) UserEquipment(Config, x, Logger), 1:numUsers);
end
	