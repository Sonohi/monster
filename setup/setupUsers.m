function Users = setupUsers (Config, Logger, Layout)
	% setupUsers - performs the necessary setup for the UEs in the simulation
	%	
	% :param Config: MonsterConfig simulation config class instance
	%	:param Logger: MonsterLog instance 
	% :param Layout: NetworkLayout instance
	% :returns Users: Array<UserEquipment> simulation UEs class instances

	Logger.log('(SETUP - setupUsers) setting up UEs', 'DBG');
	numUsers = Config.Ue.number;
	Users = arrayfun(@(x) UserEquipment(Config, x, Logger, Layout), 1:numUsers);
end
	