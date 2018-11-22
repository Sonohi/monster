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
		Traffic = struct('generatorId', 1, 'startTime', 0)
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
		
		% Change queue
		function obj = set.Queue(obj, queue)
			obj.Queue = queue;
		end
		
		function obj = move(obj, round)
			obj.Position(1:3) = obj.Mobility.Trajectory(round+1,:);
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

		function obj = generateTransportBlock(obj, Stations, Config)
			% generateTransportBlock is used to create a TB with dummy data for the UE
			%
			% :obj: UserEquipment instance
			% :Stations: Array<EvolvedNodeB> instances
			% :Config: MonsterConfig instance
			%

			% Get the current serving station for this UE
			enb = Stations([Stations.NCellID] == user.ENodeBID);

			% Find the schedule of this UE in the eNodeB
			ueScheduleIndexes = find([enb.ScheduleDL.UeId] == obj.NCellID);
			qsz = obj.Queue.Size
			numPrb = length(ueScheduleIndexes)
			if numPrb > 0 && qsz > 0:
				% Get the scheduling slots assigned to this UE and the averages
				ueSchedule = enb.ScheduleDL(ueScheduleIndexes);
				avMcs = round(sum([ueSchedule.Mcs])/numPrb);
				avMord = round(sum([ueSchedule.ModOrd])/numPrb);

				% the TB is created of a size that matches the allocation that the 
				% PDSCH symbols will have on the grid and the rate matching for the CWD
				[~, mod, ~] = lteMCS(avMCS);
				enb.Tx.PDSCH.Modulation = mod;
				enb.Tx.PDSCH.PRBSet = (ueScheduleIndexes - 1).';	
				[~,info] = ltePDSCHIndices(enb,enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
				TbInfo.rateMatch = info.G;
				% the redundacy version (RV) is defaulted to 0
				TbInfo.rv = 0;
				% Finally, we need to calculate the TB size given the scheduling
				TbInfo.tbSize = lteTBS(numPRB, avMCS);

				% Encode the SQN and the HARQ process ID into the TB if retransmissions are on
				% Use the first 13 bits for that. 
				% The first 3 are the HARQ PID, the other 10 are the SQN.
				newTb = false;
				if Config.Harq.active
					[Station, sqn] = getSqn(Station, User.NCellID, 'outFormat', 'b');
					[Station, harqPid, newTb] = getHarqPid(Station, User, sqn, 'outFormat', 'b', 'inFormat', 'b');
					ctrlBits = cat(1, harqPid, sqn);
					tbPayload = randi([0 1], TbInfo.tbSize - length(ctrlBits), 1);
					tb = cat(1, ctrlBits, tbPayload);
					if newTb
						Station = setArqTb(Station, User, sqn, timeNow, tb);
						Station = setHarqTb(Station, User, harqPid, timeNow, tb);
					end
				else
					tb = randi([0 1], TbInfo.tbSize, 1);
				end



			else
				% UE not scheduled or has nothing to send in the transmission queue
				obj.TransportBlock = [];
				obj.TransportBlockInfo = [];
			end

		
		end

		function obj = donwlinkReception(obj, Stations)
			% downlinkReception is used to handle the reception and demodulation of a DL waveform
			%
			% :obj: UserEquipment instance
			% :Stations: Array<EvolvedNodeB>
			%

			% Get the current serving station for this UE
			enb = Stations([Stations.NCellID] == user.ENodeBID);

		
		end
		
		
	end
	
	
end
