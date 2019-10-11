classdef Scheduler < matlab.mixin.Copyable
	properties
        ScheduledUsers; % List of user objects
        enbObj; % Parent enodeB EvolvedNodeB object
        PRBsActive;% List of users and the respective PRBs allocated with MCS and NDI
				PRBSet; % PRBs used for user data, these can be allocated
        Logger;
				SchedulerType; % Type of scheduling algorithm used.
				HarqActive; % If Harq is enabled
				Config;
	end

	properties(SetAccess='protected')
		RoundRobinQueue = []; % Prioritized list of users (FIFO)
	end
	

	methods
		% Constructor
				function obj = Scheduler(enbObj, Logger, Config, NRB)
						if ~isa(enbObj, 'EvolvedNodeB')
							Logger.log('The parent object is not of type EvolvedNodeB','ERR', 'Scheduler:NotEvolvedNodeB')
						end

            obj.enbObj = enbObj;
						obj.Logger = Logger;
            obj.SchedulerType = Config.Scheduling.type;
						obj.PRBSet = 1:NRB;
						obj.PRBsActive = struct('UeId', {}, 'MCS', {}, 'NDI', {}, 'ModOrd', {});
						obj.HarqActive = Config.Harq.active;
						obj.Config = Config;
						
						
				end

        
        function obj = scheduleUsers(obj, Users)
						% Given the scheduler type and the users for scheduled, turn a list of PRBs for each user ID
						% Need access to user specific variables, thus users are given as input parameter

						% If no users are associated, nothing to do.
						if ~isempty(obj.enbObj.AssociatedUsers)
							% update userids for scheduling
							obj.updateUsers();
							
							% Initialize the structure
							obj.PRBsActive(obj.PRBSet) = struct('UeId', -1, 'MCS', -1, 'NDI', -1, 'ModOrd', -1);
							
							% Run scheduling algorithm
							obj.allocateResources(Users);

						else
							obj.Logger.log('No Users associated, nothing to schedule.','WRN');
						end
        end
				
				function obj = clearRoundRobinQueue(obj)
					obj.RoundRobinQueue = [];
				end


        function obj = reset(obj)
            
            obj.ScheduledUsers = [];
            obj.PRBsActive = [];

	
			end
		
	end	

	methods(Access='private')
		function obj = allocateResources(obj, Users)
			% Given the type of the scheduler, allocate the resources to the
			% users
			
			
			switch obj.SchedulerType
				case 'roundRobin'
					obj.RoundRobinAlgorithm(Users);
				otherwise
					obj.Logger.log('Unknown scheduler pype','ERR','MonsterScheduler:UnknownSchedulerType');
					
			
			
			end
		
		end

		function obj = RoundRobinAlgorithm(obj, Users)
			% Filter users from the scheduled list
			[obj.PRBsActive, obj.RoundRobinQueue] = roundrobin(obj.enbObj, Users, obj.ScheduledUsers, obj.RoundRobinQueue, obj.PRBsActive, obj.HarqActive, obj.Config);

		end
		
		% function obj = RoundRobinAlgorithm(obj)
		% 	% Classic implementation of the Roundrobin algorithm.
		% 	% :Mapping: A list of PRBs is returned with corresponding UeId
		% 	% :NextRound: A list of UeIds which have not been allocated
		% 	% resources


		% 	% Compute the number of resources available
		% 	numPRBs = length(obj.PRBsActive);

		% 	% Compute the number of users required for scheduling (including those not scheduled previous round)
		% 	numUsers = length(obj.ScheduledUsers)+length(obj.RoundRobinQueue);

		% 	userIds = [obj.ScheduledUsers.UeId];
			
		% 	% Get user Ids from previous round
		% 	if ~isempty(obj.RoundRobinQueue)
		% 		queueIds = [obj.RoundRobinQueue.UeId];
		% 		userIds = userIds(userIds ~= queueIds);
		% 	else
		% 		queueIds = [];
		% 	end
			
		% 	% Compute the number of resources per user ( previous roundrobin
		% 	% queued have priority)
			
		% 	% Set the minimum number of resources per user
		% 	minPRBSUser = 5;
		% 	usedPRBS = 0;
			
		% 	% Total number of queued users
		% 	numQueue = length(queueIds);
		% 	numUsers = length(userIds);
			
		% 	% Check if the number of users queued exceed the resources
		% 	% available given the minimum PRBS per user
		% 	avgPRBsQueue = floor(numPRBs/numQueue);
		% 	if avgPRBsQueue < minPRBSUser
		% 		% If it is less, the queue must be used as priority
		% 		% Add to PRBsActive and remove from queue
		% 		for iUser = 1:numQueue
		% 			PRBSet = 1+usedPRBS:avgPRBsQueue+usedPRBS;
		% 			obj.setPRBsActiveSet(PRBSet, queueIds(iUser),[]);
		% 			usedPRBS = usedPRBS + avgPRBsQueue;
		% 		end
			
		% 	end
			
		% 	% If the queue users do not exceed the resources available,
		% 	% additional users can be scheduled. We compute the number of
		% 	% PRBs per user given a minimum size.
			
		% 	totUsers = numQueue+numUsers;
		% 	totUserList = [queueIds userIds];
		% 	if totUsers * minPRBSUser > numPRBs
		% 		% If the total amount of users exceed the PRBs available, the
		% 		% users in the queue are given priority
		% 		% Set prioritized queue

			
		% 		while usedPRBS < numPRBs
		% 			for iUser = totUserList
		% 				PRBSet = 1+usedPRBS:minPRBSUser+usedPRBS;
		% 				obj.setPRBsActiveSet(PRBSet, iUser,[]);
		% 				usedPRBS = usedPRBS + avgPRBsQueue;
						
		% 				% If user is in roundrobin queue, remove from FIFO
						
		% 			end
					
		% 		end
				
				
		% 		% Find users not scheduled and add them to the queue
				
		% 	else
		% 		% Compute the number of PRBS per user
		% 		avgPRBUser = floor(numPRBs/totUsers);
		% 		for iUser = totUserList
		% 			PRBSet = 1+usedPRBS:avgPRBUser+usedPRBS;
		% 			obj.setPRBsActiveSet(PRBSet, iUser,[]);
		% 			usedPRBS = usedPRBS + avgPRBUser;
		% 		end
				
		% 		% Clear roundrobin queue as all have been allocated.
		% 		obj.clearRoundRobinQueue();
				
		% 	end
			
		% end

						
		function obj = setPRBsActiveSet(obj, PRBSet, UeId, MCS)
			% Utility function for setting a set of PRBS to a UeId with a
			% given MCS.
			for iPRB = PRBSet
				if obj.PRBsActive(iPRB).UeId ~= -1
					obj.Logger.log('Overwriting allocated PRB index, not ment to happen..','ERR','MonsterScheduler:ResourceDoubleAllocated');
				end
				obj.PRBsActive(iPRB).UeId = UeId;
				obj.PRBsActive(iPRB).MCS = MCS;
			end
			
		end

		function obj = updateUsers(obj)
			% Synchronize the list of scheduled users to that of the associated users of the eNodeB.
			associatedUsers = [obj.enbObj.AssociatedUsers.UeId];

			
			% If the list of scheduled users is empty, add all associated users
			if isempty(obj.ScheduledUsers)
				% Add users
				for UeIdx = 1:length(associatedUsers)
					obj.addUser(associatedUsers(UeIdx));
				end
			
			% If not empty, find out which ones to add
			elseif any(~ismember(associatedUsers, obj.ScheduledUsers))
				toAdd = associatedUsers(~ismember(associatedUsers, obj.ScheduledUsers));
				for UeIdx = 1:length(toAdd)
					obj.addUser(toAdd(UeIdx))
				end
			end
			
			% Check if any associated Users are no longer associated, thus remove them from the scheduler
			if any(~ismember(obj.ScheduledUsers, associatedUsers))
				toRemove = obj.ScheduledUsers(~ismember(obj.ScheduledUsers, associatedUsers));
				for UeIdx = 1:length(toRemove)
					obj.removeUser(toRemove(UeIdx))
				end
			end
	end
	
	function obj = addUser(obj, UserId)
		obj.ScheduledUsers = [obj.ScheduledUsers UserId];

	end

	function obj = removeUser(obj, UserId)
		obj.ScheduledUsers = obj.ScheduledUsers(obj.ScheduledUsers ~= UserId);
	end

	function obj = updateActivePRBs(obj, AbsMask)
			% Update the number of active PRBs based on the mask

	end

end
end
