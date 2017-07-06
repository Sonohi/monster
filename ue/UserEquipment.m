%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		ENodeB;
		EstChannelGrid;
		Interference;
		NoiseEst;
		NoiseFigure;
		Offset;
		Position;
		PLast; % indexes in trajectory vector of the latest position of the UE
		Queue;
		RxWaveform;
		RxSubFrame;
    EqSubFrame;
		PlotStyle;
		Scheduled;
		Sinr;
		TLast; % timestamp of the latest movement done by the UE
		Trajectory;
		UeId;
		Velocity;
		WCqi;
  end

	methods
		% Constructor
		function obj = UserEquipment(Param, userId)
			obj.ENodeB = 0;
			obj =	setQueue(obj, struct('Size', 0, 'Time', 0, 'Pkt', 0));
			obj.RxWaveform = zeros(Param.numSubFramesMacro * 307.2, 1);
			obj.Scheduled = false;
			obj.UeId = userId;
			obj.WCqi = 6;
			obj.NoiseFigure = Param.UENoiseFigure;
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
			obj.Interference = 0;
		end

		% sets user trajectory
		function obj = setTrajectory(obj, Param)
			[x, y] = mobility(Param.mobilityScenario);
			obj.Trajectory(1:length(x),1) = x;
			obj.Trajectory(1:length(y),2) = y;
			obj.Position = [obj.Trajectory(1, 1) obj.Trajectory(1, 2) Param.UEHeight];

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

		% demodulate RX waveform
		function obj = demodulateRxWaveform(obj, enbObj)
			ue = cast2Struct(obj);
			enb = cast2Struct(enbObj);
			obj.RxSubFrame = lteOFDMDemodulate(enb, ue.RxWaveform);
		end

		% estimate channel
		function obj = estimateChannel(obj, enbObj, cec)
			ue = cast2Struct(obj);
			enb = cast2Struct(enbObj);
			[obj.EstChannelGrid, obj.NoiseEst] = lteDLChannelEstimate(enb, cec, ue.RxSubFrame);
		end

    % equalizer
    function obj = equalize(obj)
       obj.EqSubFrame = lteEqualizeMMSE(obj.RxSubFrame, obj.EstChannelGrid, obj.NoiseEst);
    end

		% select CQI
		function obj = selectCqi(obj, enbObj)
			ue = cast2Struct(obj);
			enb = cast2Struct(enbObj);
			[obj.WCqi, obj.Sinr] = lteCQISelect(enb, enb.PDSCH, ue.EstChannelGrid, ue.NoiseEst);
		end

		% move User
		function obj = move(obj, ts, Param)
			% if we are at the beginning, don't move
			if ts ~0

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

		% set interference value
		function obj = set.Interference(obj, num)
			obj.Interference = num;
		end

		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end

	end

	methods (Access = private)

	end

end
