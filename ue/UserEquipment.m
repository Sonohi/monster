%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		ueId;
		velocity;
		queue;
		eNodeB;
		scheduled;
		Position;
		wCqi;
	end

	methods
		% Constructor
		function obj = UserEquipment(Param, userId)
			obj.ueId = userId;
			obj.velocity = Param.velocity;
			obj.queue = struct('size', 0, 'time', 0, 'pkt', 0);
			obj.eNodeB = 0;
			obj.scheduled = false;
			obj.wCqi;
		end

		% Posiiton UE
		function obj = set.Position(obj, pos)
			obj.Position = pos;
		end

	end

	methods (Access = private)

	end
end
