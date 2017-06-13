%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		ENodeB;
		EstChannelGrid;
		NoiseEst;
		Position;
		Queue;
		RxWaveform;
		RxSubFrame;
		Scheduled;
		Sinr;
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
			obj.Velocity = Param.velocity;
			obj.WCqi = 6;
		end

		% Posiiton UE
		function obj = set.Position(obj, pos)
			obj.Position = pos;
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

		% select CQI
		function obj = selectCqi(obj, enbObj)
			ue = cast2Struct(obj);
			enb = cast2Struct(enbObj);
			[obj.WCqi, obj.Sinr] = lteCQISelect(enb, enb.PDSCH, ue.EstChannelGrid, ue.NoiseEst);
		end

	end

	methods (Access = private)
		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end
	end

end
