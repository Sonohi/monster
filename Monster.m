classdef Monster < handle
	% This class provides the main logic for a simulation
	% An instance of the class Monster has the following properties
	% 
	% :Config: (MonsterConfig) simulation config class instance
	% :Stations: (Array<EvolvedNodeB>) simulation eNodeBs class instances
	% :Users: (Array<UserEquipment>) simulation UEs class instances
	% :Channel: (Channel) simulation channel class instance
	% :Traffic: (TrafficGenerator) simulation traffic generator class instance

	properties 
		Config;
		Stations;
		Users;
		Channel;
		Traffic;
		Results;
	end

	methods 
		function obj = Monster(Config, Stations, Users, Channel, Traffic, Results)
			obj.Config = Config;
			obj.Stations = Stations;
			obj.Users = Users;
			obj.Channel = Channel;
			obj.Traffic = Traffic;		
			obj.Results = Results;
		end

		function run(obj)
		end

	end	

	methods (Access = private)
	end
end