function Channel = setupChannel (Cells, Users, Layout, Config, Logger)
	% setupChannel - performs the necessary setup for the channel in the simulation
	%	
	% :param Cells: Array<EvolvedNodeB> simulation eNodeBs class instances
	% :param Users: Array<UserEquipment> simulation UEs class instances
	% :param Layout: NetworkLayout instance
	% :param Config: MonsterConfig simulation config class instance
	% :param Logger: MonsterLog instance
	%	
	% :returns Channel: MonsterChannel simulation channel class instance

	Logger.log('(SETUP - setupChannel) setting up Channel', 'DBG');
	Channel = MonsterChannel(Cells, Users, Layout, Config, Logger);
	
end
	