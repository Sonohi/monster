classdef Scheduler < matlab.mixin.Copyable
	properties
		ScheduledUsers; % List of user objects
		enbObj; % Parent enodeB EvolvedNodeB object
		PRBsActive;% List of users and the respective PRBs allocated with MCS
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
			obj.PRBsActive = struct('UeId', {}, 'MCS', {}, 'ModOrd', {});
			obj.PRBsActive(obj.PRBSet) = struct('UeId', -1, 'MCS', -1, 'ModOrd', -1);
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
			obj.PRBsActive(obj.PRBSet) = struct('UeId', -1, 'MCS', -1, 'ModOrd', -1);
		end
		
	end
	
	methods(Access='private')
		function obj = allocateResources(obj, Users)
			% Given the type of the scheduler, allocate the resources to the
			% users
			%
			% Array<Users> array of user objects.
			switch obj.SchedulerType
				case 'roundRobin'
					obj.RoundRobinAlgorithm(Users);
				otherwise
					obj.Logger.log('Unknown scheduler pype','ERR','MonsterScheduler:UnknownSchedulerType');
					
			end
			
		end
		
		function queueIds = getQueue(obj)
			
			if ~isempty(obj.RoundRobinQueue)
				queueIds = [obj.RoundRobinQueue obj.ScheduledUsers(~ismember(obj.ScheduledUsers, obj.RoundRobinQueue))];
			else
				queueIds = obj.ScheduledUsers;
			end
			
		end
		
		function obj = RoundRobinAlgorithm(obj, Users)
			% Call round robin scheduler script
			%
			% Array<Users> array of user objects.
			
			queueIds = obj.getQueue();
			UserObjs = Users(ismember([Users.NCellID],queueIds));
			if obj.HarqActive
				rtxInfo = obj.getUserRetransmissionQueues(queueIds);
			end
			
			PRBSNeeded = obj.getPRBSNeeded(UserObjs, rtxInfo);
			
			[obj.PRBsActive, obj.RoundRobinQueue] = roundrobin(obj.enbObj, queueIds, Users, obj.PRBsActive, PRBSNeeded, obj.Config);
			
			obj.setRetransmissionState(rtxInfo);
		end
		
		function obj = setRetransmissionState(obj, rtxInfo)
			% Get unique scheduled users
			scheduledUsers = unique([obj.PRBsActive.UeId]);
			
			for iUser = scheduledUsers
				% Find users rtx info
				rtx = rtxInfo([rtxInfo.UeId] == iUser);
				if ~isempty(rtx)
				% set retransmission state if the scheduled is a retransmission
				switch rtx.proto
					case 1
						obj.enbObj.Mac.HarqTxBuffers.setRetransmissionState(rtx.identifier);
					case 2
						obj.enbObj.Rlc.ArqTxBuffers.setRetransmissionState(rtx.identifier);
				end
				end

			end
			
			
			
		end
		
		function rtxInfo = getUserRetransmissionQueues(obj, UserIds)
			
			
			rtxInfo = struct('proto', [], 'identifier', [], 'UeId', []);
			rtxInfo(1:length(UserIds)) = struct('proto', -1, 'identifier', -1, 'UeId', -1);
			for iUser = 1:length(UserIds)
				userId = UserIds(iUser);
				% RLC queue check
				iUserRlc = find([obj.enbObj.Rlc.ArqTxBuffers.rxId] == userId);
				arqRtxInfo = obj.enbObj.Rlc.ArqTxBuffers(iUserRlc).getRetransmissionState();
				
				% MAC queues check
				iUserMac = find([obj.enbObj.Mac.HarqTxProcesses.rxId] == userId);
				harqRtxInfo = obj.enbObj.Mac.HarqTxProcesses(iUserMac).getRetransmissionState();
				if harqRtxInfo.flag
					rtxInfo(iUser).proto = 1;
					rtxInfo(iUser).identifier = harqRtxInfo.procIndex;
					rtxInfo(iUser).UeId = userId;
				elseif arqRtxInfo.flag
					rtxInfo(iUser).proto = 2;
					rtxInfo(iUser).identifier = arqRtxInfo.bufferIndex;
					rtxInfo(iUser).UeId = userId;
				else
					rtxInfo(iUser).proto = 0;
					rtxInfo(iUser).identifier = [];
				end
			end
			
		end
		
		function PRBNeed = getPRBSNeeded(obj, Users, rtxInfo)
			
			PRBNeed = zeros(length(Users),1);
			for iUser = 1:length(Users)
				user = Users(iUser);
				modOrd = obj.Config.Phy.modOrdTable(user.Rx.CQI);
				rtxSchedulingFlag = obj.HarqActive && rtxInfo(iUser).proto ~= 0;
				
				if ~rtxSchedulingFlag
					PRBNeed(iUser) = ceil(double(user.Queue.Size)/(modOrd * obj.Config.Phy.prbSymbols));
				else
					% Otherwise, use the HARQ and ARQ queues for PRBS
					tb = [];
					switch rtxInfo(iUser).proto
						case 1
							tb = obj.enbObj.Mac.HarqTxProcesses.processes(rtxInfo.identifier).tb;
						case 2
							tb = obj.enbObj.Mac.ArqTxProcesses.tbBuffer(rtxInfo.identifier).tb;
					end
					PRBNeed(iUser) = ceil(length(tb)/(modOrd * obj.Config.Phy.prbSymbols));
				end
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
			% TODO: add mask
			
		end
		
	end
end
