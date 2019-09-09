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
            obj.enbObj = enbObj;
			obj.Logger = Logger;
            obj.SchedulerType = Config.Scheduling.type;
    end
        
        function PRBList = scheduleUsers(obj, subframe)


            % Given the scheduler type and the users for scheduled, turn a list of PRBs for each user ID

            

        end

        function obj = updateUsers(obj, AssociatedUsers)
            % Check newly inputted users against list kept in the scheduler 
        
            % update obj.ScheduledUsers
        end

        function obj = updateActivePRBs(obj, AbsMask)
            % Update the number of active PRBs based on the mask

        end


        function obj = reset(obj)
            
            obj.ScheduledUsers = []
            obj.PRBsActive = []

	
		end
		
	end	
end
