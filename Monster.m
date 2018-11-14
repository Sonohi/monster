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
			% Monster constructor 
			%
			% :Config: MonsterConfig instance
			% :Stations: Array<EvolvedNodeB> instances
			% :Users: Array<UserEquipment> instances
			% :Channel: SonohiChannel instance
			% :Traffic: TrafficGenerator instance
			% :Results: MetricRecorder instance
			obj.Config = Config;
			obj.Stations = Stations;
			obj.Users = Users;
			obj.Channel = Channel;
			obj.Traffic = Traffic;		
			obj.Results = Results;
		end

		function obj = setupRound(obj, iRound)
			% setupRound configures the simulation runtime parameters prior the start of a round
			obj.Config.Runtime.currentRound = iRound;
			obj.Config.Runtime.currentTime = iRound*10e-3;  
			obj.Config.Runtime.remainingTime = (obj.Config.Runtime.totalRounds - obj.Config.Runtime.currentRound)*10e-3;
			obj.Config.Runtime.remainingRounds = obj.Config.Runtime.totalRounds - obj.Config.Runtime.currentRound - 1;
		end

		function obj = run(obj)
			% run performs all the calls to methods needed for a single simulation round
			monsterLog('(MONSTER - run) performing UE movement', 'NFO');
			obj.moveUsers();

			monsterLog('(MONSTER - run) checking UE-eNodeB association', 'NFO');
			obj.associateUsers();

			monsterLog('(MONSTER - run) updating UE transmission queues', 'NFO');
			obj.updateUsersQueues();

			monsterLog('(MONSTER - run) downlink UE scheduling', 'NFO');
			obj.schedule()

			monsterLog('(MONSTER - run) creating TB, codewords and waveforms for downlink', 'NFO');
			obj.setupStationsTransmitters();






		end

	end	

	methods (Access = private)
		function obj = moveUsers(obj)
			% moveUsers performs UE movements at the beginning of each round
			%
			% :obj: Monster instance

			arrayfun(@(x, y)x.move(y), obj.Users, obj.Config.Runtime.currentRound);
		end

		function obj = associateUsers(obj)
			% associateUsers associates UEs to eNodeBs based on the association refresh timer
			%
			% :obj: Monster instance

			if mod(obj.Config.Runtime.currentTime, obj.Config.Scheduling.refreshAssociationTimer) == 0
				monsterLog('(MONSTER - associateUsers) UEs-eNodeBs re-associating', 'NFO');
				[obj.Users, obj.Stations] = refreshUsersAssociation(obj.Users, obj.Stations, obj.Channel, obj.Config);
			else
				monsterLog('(MONSTER - associateUsers) UEs-eNodeBs not re-associated', 'NFO');
			end			
		end
		
		function obj = updateUsersQueues(obj)
			% updateUsersQueues is used to update the transmission queues for a UE based on the current simulation time
			% 
			% :obj: Monster instance
			for iUser = 1: obj.Config.Ue.number
				UeTrafficGenerator = find([obj.Traffic.id] == obj.Users(iUser).Traffic.generatorId);
				obj.Users(iUser).Queue = UeTrafficGenerator.updateTransmissionQueue(obj.Users(iUser), obj.Config.Runtime.currentTime);
			end
		end

		function obj = schedule(obj) 
			% schedule is used to perform the allocation of eNodeB resources in the downlink to the UEs
			% 
			% :obj: Monster instance
			%
			
			% Set the ShouldSchedule flag for all the eNodeBs 
			arrayfun(@(x, y)x.evaluateScheduling(y), obj.Stations, obj.Users);

			% Now call the schedule method on the eNodeBs
			arrayfun(@(x, y, z)x.downlinkSchedule(y, z), obj.Stations, obj.Users, obj.Config);

			% Finally, evaluate the power state for the eNodeBs
			arrayfun(@(x, y, z)x.evaluatePowerState(y, z), obj.Stations, obj.Config, obj.Stations)
		end

		function obj = setupStationsTransmitters(obj)
			% setupStationsTransmitters is used to pprepare the data for the downlink transmission
			% 
			% :obj: Monster instance
			%
			
			% Create the transport blocks for all the UEs
			arrayfun(@(x, y, z)x.generateTransportBlock(y, z), obj.Users, obj.Stations, Config);

			% Create the codewords for all the UEs
			arrayfun(@(x)x.generateCodeword(), obj.Users);

			% Create the symbols for all the UEs' codewords at the eNodeBs
			arrayfun(@(x, y)x.generateSymbols(y), obj.Stations, obj.Users);

			% Finally modulate the waveform for all the eNodeBs
			arrayfun(@(x)x.modulateTxWaveform(), obj.Stations);

		end



	end
end