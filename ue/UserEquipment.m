%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		ENodeB;
		Position;
		PLast; % indexes in trajectory vector of the latest position of the UE
		Queue;
		PlotStyle;
		Scheduled;
		Sinr;
		TLast; % timestamp of the latest movement done by the UE
		Trajectory;
		UeId;
		Velocity;
		RxAmpli;
		Rx;
		Codeword;
		CodewordInfo;
		TransportBlock;
		TransportBlockInfo;
		WCQI;
	end

	methods
		% Constructor
		function obj = UserEquipment(Param, userId)
			obj.ENodeB = 0;
			obj =	setQueue(obj, struct('Size', 0, 'Time', 0, 'Pkt', 0));
			obj.Scheduled = false;
			obj.UeId = userId;
			obj.PlotStyle = struct(	'marker', '^', ...
				'colour', rand(1,3), ...
				'edgeColour', [0.1 0.1 0.1], ...
				'markerSize', 8, ...
				'lineWidth', 2);
			switch Param.mobilityScenario
				case 1
					obj.Velocity = 1; % in m/s
				case 2
					obj.Velocity = 10; % in m/s
				otherwise
					sonohilog('Unknown mobility scenario selected','ERR');
					return;
			end
			obj = setTrajectory(obj, Param);
			obj.TLast = 0;
			obj.PLast = [1 1];
			obj.RxAmpli = 1;
			obj.Rx = ReceiverModule(Param);
			obj.Codeword = [];
			obj.TransportBlock = [];
		end

		% sets user trajectory
		function obj = setTrajectory(obj, Param)
			[x, y] = mobility(Param.mobilityScenario);
			obj.Trajectory(1:length(x),1) = x;
			obj.Trajectory(1:length(y),2) = y;
			obj.Position = [obj.Trajectory(1, 1) obj.Trajectory(1, 2) Param.ueHeight];

			% Plot UE posiiton and trajectory in scenario
			if Param.draw
				plotUEinScenario(obj, Param);
			end
		end

		% Change queue
		function obj = setQueue(obj, queue)
			obj.Queue = queue;
		end

		% toggle scheduled
		function obj = setScheduled(obj, status)
			obj.Scheduled = status;
		end

		% move User
		function obj = move(obj, ts, Param)
			% if we are at the beginning, don't move
			if ts ~= 0

				% delta of time since last step
				tDelta = ts - obj.TLast;

				% check if the current position is the last one of the trajectory
				if obj.PLast(1) == length(obj.Trajectory)
					% reverse the trajectory and use it upside down
					obj.Trajectory = flipud(obj.Trajectory);
					obj.PLast = [0 0];
				end

				% get current position and trajectory
				p0 = obj.Position;
				p0(3) = [];
				trj = obj.Trajectory;

				% get next position
				x1 = trj(obj.PLast(1) + 1, 1);
				y1 = trj(obj.PLast(2) + 1, 2);
				p1 = [x1, y1];

				% get distance
				dist = sqrt((p1(1)-p0(1))^2 + (p1(2)-p0(2))^2 );

				% time to pass the distance
				td = dist/obj.Velocity;

				% check whether we need to make this step
				if td >= tDelta
					% move UE and update attributes
					obj.Position = [x1 y1 obj.Position(3)];
					obj.TLast = ts;
					obj.PLast = obj.PLast + 1;
				end

			end
		end

		% set TransportBlock
		function obj = set.TransportBlock(obj, tb)
			obj.TransportBlock = tb;
		end

		% set TransportBlockInfo
		function obj = set.TransportBlockInfo(obj, info)
			obj.TransportBlockInfo = info;
		end

		% set Codeword
		function obj = set.Codeword(obj, cw)
			obj.Codeword = cw;
		end

		% set CodewordInfo
		function obj = set.CodewordInfo(obj, info)
			obj.CodewordInfo = info;
		end

		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end

		%Reset properties that change every round
		function obj = resetUser(obj)
			obj.Scheduled = false;
			obj.Codeword = [];
			obj.CodewordInfo = [];
			obj.TransportBlock = [];
			obj.TransportBlockInfo = [];
			obj.Rx = obj.Rx.resetReceiver();
		end

	end

	methods (Access = private)

	end

end
