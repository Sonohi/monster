%   USER EQUIPMENT defines a value class for creating and working with UEs

classdef UserEquipment < matlab.mixin.Copyable
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
		function obj = UserEquipment(Config, userId)
			obj.NCellID = userId;
			obj.Seed = userId*Config.Runtime.seed;
			obj.ENodeBID = -1;
			obj.NULRB = Config.Ue.subframes;
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
			obj.Mobility = Mobility(Config.Mobility.scenario, 1, Config.Mobility.seed * userId, Config);
			obj.Position = obj.Mobility.Trajectory(1,:);
			obj.TLast = 0;
			obj.PLast = [1 1];
			obj.RxAmpli = 1;
			obj.Rx = ueReceiverModule(obj, Config);
			obj.Tx = ueTransmitterModule(obj, Config);
			obj.SymbolsInfo = [];
			obj.Codeword = [];
			obj.TransportBlock = [];
			obj.TransportBlockInfo = [];
			if Config.Harq.active
				obj.Mac = struct('HarqRxProcesses', HarqRx(0, Config), 'HarqReport', struct('pid', [0 0 0], 'ack', -1));
			end
			if Config.Arq.active 
				obj.Rlc = struct('ArqRxBuffer', ArqRx());
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

		function obj = setTrafficStartTime(obj, tStart)
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
			numPrb = length(ueScheduleIndexes);
			if numPrb > 0 && obj.Queue.Size > 0
				% Get the scheduling slots assigned to this UE and the averages
				ueSchedule = enb.ScheduleDL(ueScheduleIndexes);
				avMcs = round(sum([ueSchedule.Mcs])/numPrb);

				% the TB is created of a size that matches the allocation that the 
				% PDSCH symbols will have on the grid and the rate matching for the CWD
				[~, mod, ~] = lteMCS(avMcs);
				enb.Tx.PDSCH.Modulation = mod;
				enb.Tx.PDSCH.PRBSet = (ueScheduleIndexes - 1).';	
				[~,info] = ltePDSCHIndices(enb,enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
				TbInfo.rateMatch = info.G;
				% the redundacy version (RV) is defaulted to 0
				TbInfo.rv = 0;
				% Finally, we need to calculate the TB size given the scheduling
				TbInfo.tbSize = lteTBS(numPRB, avMcs);

				% Encode the SQN and the HARQ process ID into the TB if retransmissions are on
				% Use the first 13 bits for that. 
				% The first 3 are the HARQ PID, the other 10 are the SQN.
				if Config.Harq.active
					% get the SQN: start by searching whether this is a TB 
					% that is already being transmitted and is already in the RLC buffer
					iArqBuf = find([enb.Rlc.ArqTxBuffers.rxId] == USer.NCellID);
					[enb.Rlc.ArqTxBuffers(iUser), sqnDec] = getNextSqn(enb.Rlc.ArqTxBuffers(iArqBuf));
					sqnBin = de2bi(sqnDec, 10, 'left-msb')';

					% get the HARQ PID: find the index of the process
					iHarqProc = find([enb.Mac.HarqTxProcesses.rxId] == User.NCellID);
					% Find pid
					[enb.Mac.HarqTxProcesses(iHarqProc), harqPidDec, newTb] = findProcess(enb.Mac.HarqTxProcesses(iHarqProc), sqnDec);	
					harqPidBin = de2bi(harqPidDec, 3, 'left-msb')';
	
					% Create the control bits sequence 
					ctrlBits = cat(1, harqPidBin, sqnBin);
					tbPayload = randi([0 1], TbInfo.tbSize - length(ctrlBits), 1);
					tb = cat(1, ctrlBits, tbPayload);
					if newTb
						% Set TB in the ARQ buffer
						enb.Rlc.ArqTxBuffers(iArqBuf) = enb.Rlc.ArqTxBuffers(iArqBuf).handleTbInsert(sqnDec, timeNow, tb);	

						% Set TB in the HARQ process
						enb.Mac.HarqTxProcesses(iHarqProc) = enb.Mac.HarqTxProcesses(iHarqProc).handleTbInsert(harqPidDec, timeNow, tb);	
					end
				else
					tb = randi([0 1], TbInfo.tbSize, 1);
				end
				% Set the TB and the info in the UE
				obj.TransportBlock = tb;
				obj.TransportBlockInfo = TbInfo;
			else
				% UE not scheduled or has nothing to send in the transmission queue
				obj.TransportBlock = [];
				obj.TransportBlockInfo = [];
			end

		
		end

		function obj = downlinkReception(obj, Stations, ChannelEstimator)
			% downlinkReception is used to handle the reception and demodulation of a DL waveform
			%
			% :obj: UserEquipment instance
			% :Stations: Array<EvolvedNodeB>
			% :ChannelEstimator: Channel.Estimator property 
			%

			% Get the current serving station for this UE
			enb = Stations([Stations.NCellID] == user.ENodeBID);
			% Find the schedule of this UE in the eNodeB
			ueScheduleIndexes = find([enb.ScheduleDL.UeId] == obj.NCellID);
			
			% Compute offset based on synchronization signals.
			obj.Rx = obj.Rx.computeOffset(enb);
			% Apply Offset
			if obj.Rx.Offset > length(obj.Rx.Waveform)
				monsterLog(sprintf('(USER EQUIPMENT - downlinkReception) Offset for User %i out of bounds, not able to synchronize',obj.NCellID),'WRN')
			else
				obj.Rx.Waveform = obj.Rx.Waveform(1+abs(obj.Rx.Offset):end,:);
			end

			% Conduct reference measurements
			obj.Rx = obj.Rx.referenceMeasurements(enb);

			% If the UE is not scheduled, reset the metrics for the round
			if length(ueScheduleIndexes) <= 0
				obj.Rx = obj.Rx.logNotScheduled();
			end

			% Try to demodulate
			[demodBool, obj.Rx] = obj.Rx.demodulateWaveform(enb);
			% demodulate received waveform, if it returns 1 (true) then demodulated
			if demodBool
				% Estimate Channel
				obj.Rx = obj.Rx.estimateChannel(enb, ChannelEstimator);
				% Equalize signal
				obj.Rx = obj.Rx.equaliseSubframe();
				% Estimate PDSCH (main data channel)
				obj.Rx = obj.Rx.estimatePdsch(obj, enb);
				% calculate EVM
				obj.Rx = obj.Rx.calculateEvm(enb);
				% Calculate the CQI to use
				obj.Rx = obj.Rx.selectCqi(enb);
				% Log block reception stats
				obj.Rx = obj.Rx.logBlockReception(obj);
			else
				monsterLog(sprintf('(USER EQUIPMENT - downlinkReception) not able to demodulate Station(%i) -> User(%i)...',enb.NCellID, obj.NCellID),'WRN');
				obj.Rx = obj.Rx.logNotDemodulated();
				obj.Rx.CQI = 3;
			end					
		end

		function obj = downlinkDataDecoding(obj, Config)
			% downlinkDataDecoding performs the decoding of the demodulated waveform
			% 
			% :obj: UserEquipment instance
			% :Config: MonsterConfig instance
			%

			% Currently data decoding is only used for retransmissions
			if ~isempty(obj.Rx.TransportBlock) && Config.Harq.active
				% Decode HARQ bits 
				[harqPid, iProc] = obj.Mac.HarqRxProcesses.decodeHarqPid(obj.Rx.TransportBlock);
				harqPidBits = de2bi(harqPid, 3, 'left-msb')';
				if length(harqPidBits) ~= 3
					harqPidBits = cat(1, zeros(3-length(harqPidBits), 1), harqPidBits);
				end

				if ~isempty(iProc)
					% Handle HARQ TB reception
					[obj.Mac.HarqRxProcesses, state] = obj.Mac.HarqRxProcesses.handleTbReception(iProc,obj.Rx.TransportBlock, obj.Rx.Crc, Config.Runtime.currentTime);

					% Depending on the state the process is, contact ARQ
					if state == 0
						sqn = obj.Rlc.ArqRxBuffer.decodeSqn(obj.Rx.TransportBlock);
						if ~isempty(sqn)
							obj.Rlc.ArqRxBuffer = obj.Rlc.ArqRxBuffer.handleTbReception(sqn, obj.Rx.TransportBlock, Config.Runtime.currentTime);
						end	
						% Set ACK and PID information for this UE to report back to the serving eNodeB 
						obj.Mac.HarqReport.pid = harqPidBits;
						obj.Mac.HarqReport.ack = 1;
					else
						% The process has entered or remained in the state where it needs TB copies
						% we should not then contact the ARQ, but just send back a NACK
						obj.Mac.HarqReport.pid = harqPidBits;
						obj.Mac.HarqReport.ack = 0;
					end
				end
			end
		end
		
	end	
end
