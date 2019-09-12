classdef Scheduler < matlab.mixin.Copyable
	properties
        ScheduledUsers; % List of user objects
        enbObj; % Parent enodeB EvolvedNodeB object
        PRBsActive = []; % List of users and the respective PRBs allocated with MCS and NDI
				PRBSet; % PRBs used for user data, these can be allocated
        Logger;
        SchedulerType; % Type of scheduling algorithm used.
	end

	properties(Access=Private)
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
						
						
				end
				
				function obj = allocateResources(obj)
					% Given the type of the scheduler, allocate the resources to the
					% users
					
					switch obj.SchedulerType
						case 'RoundRobin'
							[Mapping, NextRound] = obj.RoundRobinAlgorithm();
							
					
					
					end
				
				end
				
				function [Mapping, NextRound] = RoundRobinAlgorithm(obj)
					% Classic implementation of the Roundrobin algorithm.
					% :Mapping: A list of PRBs is returned with corresponding UeId
					% :NextRound: A list of UeIds which have not been allocated
					% resources


					% Compute the number of resources available
					numPRBs = length(obj.PRBsActive);

					% Compute the number of users required for scheduling (including those not scheduled previous round)
					numUsers = length(obj.ScheduledUsers)+length(obj.RoundRobinQueue);

					% Get user Ids from previous round
					queueIds = [obj.RoundRobinQueue.UeId]; 
					userIds = [obj.ScheduledUsers.UeId];

					% Removed queued Ids from list of all scheduled users
					userIds = userIds(userIds ~= queueIds);

					% Compute the minimum number of resources per user
					minPRBSUser = 10;
					usedPRBS = 0;

					% Set PRBs per user (prioritize those not scheduled previous round)
					% Loop through users
					for iUser = 1:length(queueIds)
						if usedPRBS >= numPRBs
							break;
						end
						obj.PRBsActive(1+usedPRBS:minPRBSUser+usedPRBS) = struct('UeId', queueIds(iUser));
						usedPRBS = usedPRBS + 10;
						% TODO: Remove from queue

					end

					for iUser = 1:length(userIds)
						if usedPRBS >= numPRBs
							break;
						end
						obj.PRBsActive(1+usedPRBS:minPRBSUser+usedPRBS) = struct('UeId', userIds(iUser));
						usedPRBS = usedPRBS + 10;
					end


					if usedPRBS < numPRBs
						obj.Logger.log('Not all resources allocated','WRN')
					end

					% Update queue for next round
					scheduled = [obj.PRBsActive.UeId];
					notscheduled = obj.ScheduledUsers([obj.ScheduledUsers.UeId] ~= scheduled);

					for iUser = 1:length(notscheduled)
						obj.RoundRobinQueue = [obj.RoundRobinQueue notscheduled(iUser)];
					end

					

					

					

					
					
				end
        
        function obj = scheduleUsers(obj)
						% Given the scheduler type and the users for scheduled, turn a list of PRBs for each user ID

						% If no users are associated, nothing to do.
						if ~isempty(obj.enbObj.AssociatedUsers)
							% update users
							obj.updateUsers();
							
							% Initialize the structure
							obj.PRBsActive(obj.PRBSet) = struct('UeId', -1, 'MCS', -1);
							
							% Run scheduling algorithm
							obj.allocateResources();

						else
							obj.Logger.log('No Users associated, nothing to schedule.','WRN');
						end
        end

        function obj = updateUsers(obj)
            % Synchronize the list of scheduled users to that of the associated users of the eNodeB.
						associatedUsers = obj.enbObj.AssociatedUsers;
						
						% If the list of scheduled users is empty, add all associated users
						if isempty(obj.ScheduledUsers)
							% Add users
							for UeIdx = 1:length(associatedUsers)
								obj.addUser(associatedUsers(UeIdx));
							end
						
						% If not empty, find out which ones to add
						elseif any(~ismember([associatedUsers.UeId], [obj.ScheduledUsers.UeId]))
							toAdd = associatedUsers(~ismember([associatedUsers.UeId], [obj.ScheduledUsers.UeId]));
							for UeIdx = 1:length(toAdd)
								obj.addUser(toAdd(UeIdx))
							end
						end
						
						% Check if any associated Users are no longer associated, thus remove them from the scheduler
						if any(~ismember([obj.ScheduledUsers.UeId], [associatedUsers.UeId]))
							toRemove = obj.ScheduledUsers(~ismember([obj.ScheduledUsers.UeId], [associatedUsers.UeId]));
							for UeIdx = 1:length(toRemove)
								obj.removeUser(toRemove(UeIdx).UeId)
							end
						end
				end
				
				function obj = addUser(obj, UserId)
					obj.ScheduledUsers = [obj.ScheduledUsers UserId];
		
				end

				function obj = removeUser(obj, UserId)
					obj.ScheduledUsers = obj.ScheduledUsers([obj.ScheduledUsers.UeId] ~= UserId);
				end

        function obj = updateActivePRBs(obj, AbsMask)
            % Update the number of active PRBs based on the mask

        end


        function obj = reset(obj)
            
            obj.ScheduledUsers = [];
            obj.PRBsActive = [];

	
		end
		
	end	
end
