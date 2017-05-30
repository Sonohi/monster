%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		ENodeB;
		Position;
		Queue;
		RxWaveform;
		Scheduled;
		UeId;
		Velocity;
		WCqi;
	end

	methods
		% Constructor
		function obj = UserEquipment(Param, userId)
			obj.ENodeB = 0;
			obj.Queue = struct('Size', 0, 'Time', 0, 'Pkt', 0);
			obj.RxWaveform = zeros(Param.numSubFramesMacro * 307.2, 1);
			obj.Scheduled = false;
			obj.UeId = userId;
			obj.Velocity = Param.velocity;
			obj.WCqi;
		end

		% Posiiton UE
		function obj = set.Position(obj, pos)
			obj.Position = pos;
		end

	end

	methods (Access = private)

	end
end
