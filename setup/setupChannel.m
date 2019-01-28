function Channel = setupChannel (Stations, Users, Config)
	% setupChannel - performs the necessary setup for the channel in the simulation
	%	
	% Syntax: Channel = setupChannel(Stations, Users, Config)
	% Parameters:
	% :Stations: (Array<EvolvedNodeB>) simulation eNodeBs class instances
	% :Users: (Array<UserEquipment>) simulation UEs class instances
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Channel: (ChBulk_v2) simulation channel class instance

	monsterLog('(SETUP - setupChannel) setting up Channel', 'NFO');
	Channel = MonsterChannel(Stations, Users, Config);
	
end
	