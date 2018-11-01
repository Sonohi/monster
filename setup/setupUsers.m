function Users = setupUsers (Config)
	% setupUsers - performs the necessary setup for the UEs in the simulation
	%	
	% Syntax: Users = setupUsers(Config)
	% Parameters:
	% :Config: (MonsterConfig) simulation config class instance
	%	Returns:
	% :Users: (Array<UserEquipment>) simulation UEs class instances

	monsterLog('(SETUP - setupUsers) setting up UEs', 'NFO');
	rangeA = 1;
	rangeB = Config.Ue.number;
	Users(rangeA:rangeB) = UserEquipment(Config, rangeA:rangeB);
	
	if Config.SimulationPlot.runtimePlot
		legend('Location','northeastoutside')
	end
	
end
	