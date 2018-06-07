%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		NCellID;
		ENodeBID;
		NULRB;
		RNTI;
		DuplexMode;
		CyclicPrefixUL;
		NSubframe;
		NFrame;
		NTxAnts;
		Position;
		PLast; % indexes in trajectory vector of the latest position of the UE
		Queue;
		PlotStyle;
		Scheduled;
		Sinr;
		TLast; % timestamp of the latest movement done by the UE
		Trajectory;
		Velocity;
		RxAmpli;
		Rx;
		Tx;
		Symbols;
		SymbolsInfo;
		Codeword;
		CodewordInfo;
		TransportBlock;
		TransportBlockInfo;
		Mac;
		Rlc;
		SchedulingSlots;
		Hangover;
		Pmax;
		Seed;
		Mobility;
		TrafficStartTime;
	end
	
	methods
		% Constructor
		function obj = UserEquipment(Param, userId)
			obj.NCellID = userId;
			obj.Seed = userId*Param.seed;
			obj.ENodeBID = -1;
			obj.NULRB = Param.numSubFramesUE;
			obj.RNTI = 1;
			obj.DuplexMode = 'FDD';
			obj.CyclicPrefixUL = 'Normal';
			obj.NSubframe = 0;
			obj.NFrame = 0;
			obj.NTxAnts = 1;
			obj.Queue = struct('Size', 0, 'Time', 0, 'Pkt', 1);
			obj.Scheduled = false;
			obj.PlotStyle = struct(	'marker', '^', ...
				'colour', rand(1,3), ...
				'edgeColour', [0.1 0.1 0.1], ...
				'markerSize', 8, ...
				'lineWidth', 2);
			obj.Mobility = MMobility('pedestrian', 1, Param.mobilitySeed * userId, Param);
			obj.Position = [obj.Mobility.Trajectory(1,:), Param.ueHeight];
			if Param.draw
				obj.plotUEinScenario(Param);
			end
			obj.TLast = 0;
			obj.PLast = [1 1];
			obj.RxAmpli = 1;
			obj.Rx = ueReceiverModule(Param, obj);
			obj.Tx = ueTransmitterModule(Param, obj);
			obj.SymbolsInfo = [];
			obj.Codeword = [];
			obj.TransportBlock = [];
			obj.TransportBlockInfo = [];
			if Param.rtxOn
				obj.Mac = struct('HarqRxProcesses', HarqRx(Param, 0), 'HarqReport', struct('pid', [0 0 0], 'ack', -1));
				obj.Rlc = struct('ArqRxBuffer', ArqRx(Param, 0));
			end
			obj.Hangover = struct('TargetEnb', -1, 'HoState', 0, 'HoStart', -1, 'HoComplete', -1);
			obj.Pmax = 10; %10dBm
    end
		
		% Change queue
		function obj = set.Queue(obj, queue)
			obj.Queue = queue;
		end
		
		function obj = move(obj, round)
			obj.Position(1:2) = obj.Mobility.Trajectory(round+1,:);
		end
		
		% toggle scheduled
		function obj = setScheduled(obj, status)
			obj.Scheduled = status;
		end

		function obj = set.TrafficStartTime(obj, tStart)
			% Used to set the starting time for requesting traffic
			obj.TrafficStartTime = tStart;
		end
		
		% set TransportBlock
		function obj = set.TransportBlock(obj, tb)
			obj.TransportBlock = tb;
		end
		
		% set TransportBlockInfo
		function obj = set.TransportBlockInfo(obj, info)
			obj.TransportBlockInfo = info;
		end
		
		% Create codeword
		function obj = createCodeword(obj)
			% perform CRC encoding with 24A poly
			encTB = lteCRCEncode(obj.TransportBlock, '24A');

			% create code block segments
			cbs = lteCodeBlockSegment(encTB);

			% turbo-encoding of cbs
			turboEncCbs = lteTurboEncode(cbs);

			% finally rate match and return codeword
			cwd = lteRateMatchTurbo(turboEncCbs, obj.TransportBlockInfo.rateMatch, obj.TransportBlockInfo.rv);

			obj.Codeword = cwd;
		end
				
		% set SymbolsInfo
		function obj = set.SymbolsInfo(obj, info)
			obj.SymbolsInfo = info;
		end
		
		% set NSubframe
		function obj = set.NSubframe(obj, num)
			obj.NSubframe = num;
		end
		
		% set NFrame
		function obj = set.NFrame(obj, num)
			obj.NFrame = num;
		end
		
		% set NULRB
		function obj = set.NULRB(obj, num)
			obj.NULRB = num;
		end
		
		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end
		
		% Find indexes in the serving eNodeB for the UL scheduling
		function obj = setSchedulingSlots(obj, Station)
			obj.SchedulingSlots = find(Station.ScheduleUL == obj.NCellID);
			obj.NULRB = length(obj.SchedulingSlots);
		end
		
		% Reset the HARQ report
		function obj = resetHarqReport(obj)
			obj.Mac.HarqReport = struct('pid', [0 0 0], 'ack', -1);
		end
		
		%Reset properties that change every round
		function obj = reset(obj)
			obj.Scheduled = false;
			obj.Symbols = [];
			obj.SymbolsInfo = [];
			obj.Codeword = [];
			obj.CodewordInfo = [];
			obj.TransportBlock = [];
			obj.TransportBlockInfo = [];
			obj.Tx = obj.Tx.reset();
			obj.Rx = obj.Rx.reset();
		end
		
		function plotUEinScenario(obj, Param)
				x0 = obj.Position(1);
				y0 = obj.Position(2);

				% UE in initial position
				plot(Param.LayoutAxes,x0, y0, ...
						'Marker', obj.PlotStyle.marker, ...
						'MarkerFaceColor', obj.PlotStyle.colour, ...
						'MarkerEdgeColor', obj.PlotStyle.edgeColour, ...
						'MarkerSize',  obj.PlotStyle.markerSize, ...
						'DisplayName', strcat('UE ', num2str(obj.NCellID)));

				% Trajectory
				plot(Param.LayoutAxes,obj.Mobility.Trajectory(:,1), obj.Mobility.Trajectory(:,2), ...
						'Color', obj.PlotStyle.colour, ...
						'LineStyle', '--', ...
						'LineWidth', obj.PlotStyle.lineWidth,...
						'DisplayName', strcat('UE ', num2str(obj.NCellID), ' trajectory'));
				drawnow()
		end
		
		
	end
	
	
end
