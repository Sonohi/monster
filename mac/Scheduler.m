classdef Scheduler < matlab.mixin.Copyable
	properties
        ScheduledUsers; % List of user objects
        enbObj; % Parent enodeB EvolvedNodeB object
        PRBsActive = [];
        Logger;
        SchedulerType;
	end
	
	methods
		% Constructor
				function obj = Scheduler(enbObj, Logger, Config)
						if ~isa(enbObj, 'EvolvedNodeB')
							Logger.log('The parent object is not of type EvolvedNodeB','ERR', 'Scheduler:NotEvolvedNodeB')
						end

            obj.enbObj = enbObj;
						obj.Logger = Logger;
            obj.SchedulerType = Config.Scheduling.type;
    end
        
        function PRBList = scheduleUsers(obj, subframe)


						% Given the scheduler type and the users for scheduled, turn a list of PRBs for each user ID

			
						% If no users are associated, nothing to do.
						if ~isempty(obj.enbObj.AssociatedUsers)
							% update users
							obj.updateUsers();

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
