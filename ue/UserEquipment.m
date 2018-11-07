%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment
	%   USER EQUIPMENT defines a value class for creating and working with UEs
	properties
		%Matlab tool box for LTE
		RNTI;			%Radio network temporary identifier. Required for matlab LTE toolbox
		DuplexMode; 	%Duplex mode, e.g. 'FDD' or 'TDD' (matlab LTE toolbox), when removed matalb chrashes
		CyclicPrefixUL; %Cyclic Prefix (matlab LTE toolbox)

		%Practical info about the UE
		NCellID;		%ID number for the UE
		NTxAnts;		%Number of transmission antennas
		ENodeBID;		%Associated eNB
		Position;		%Coordinates to the UE location
		PLast; 			% indexes in trajectory vector of the latest position of the UE
		TLast; 			% timestamp of the latest movement done by the UE
		Trajectory;		%Movement track
		Velocity;		%Speed fo the UE
		Mobility;		%Mobility scenario

		%Frames and subframes
		NULRB;			%Something with subframes
		NSubframe;		%
		NFrame;			%
		
		%Draw and plot functions
		PlotStyle;		%Style to control plot functions
		
		%Scheduling info
		Queue;
		Scheduled;		
		SchedulingSlots;
		
		%Reciever and Transmitter modules and similar
		RxAmpli;
		Rx;				%Reciver module
		Tx;				%Transmit module
		Symbols;		%Symbols
		SymbolsInfo;	%Info about symbols
		Codeword;		
		CodewordInfo;
		TransportBlock;
		TransportBlockInfo;
		Mac;			%For Harq Tx Processes
		Rlc;			%For Arq Tx Buffers
		Hangover;		%Handover info

		%Simulation specific properties
		Seed;			%Seed to repeat or differentiate

		%Other properteis
		Sinr;			%Signal to noise ratio, though connection is very unclear
		Pmax;			%Maximum power
		TrafficStartTime; %Used to set the starting time for requesting traffic
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
			obj.Mobility = MMobility(Param.mobilityScenario, 1, Param.mobilitySeed * userId, Param);
			obj.Position = obj.Mobility.Trajectory(1,:);
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
		
		
		function obj = move(obj, round)
			obj.Position(1:3) = obj.Mobility.Trajectory(round+1,:);
		end
		
		% toggle scheduled
		function obj = setScheduled(obj, status)
			obj.Scheduled = status;
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
