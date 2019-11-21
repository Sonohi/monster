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
		Scheduled = struct('DL', false, 'UL', false);
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
		Mimo;
		Logger;
	end
	
	methods
		% Constructor
		function obj = UserEquipment(Config, userId, Logger, Layout)
			obj.Logger = Logger;
			obj.NCellID = userId;
			obj.Seed = userId*Config.Runtime.seed;
			obj.Mimo = generateMimoConfig(Config);
			obj.ENodeBID = -1;
			obj.NULRB = Config.Ue.numPRBs;
			obj.RNTI = 1;
			obj.DuplexMode = 'FDD';
			obj.CyclicPrefixUL = 'Normal';
			obj.NSubframe = 0;
			obj.NFrame = 0;
			obj.NTxAnts = obj.Mimo.numAntennas;
			obj.Queue = struct('Size', 0, 'Time', 0, 'Pkt', 1);
			obj.PlotStyle = struct(	'marker', '^', ...
				'colour', rand(1,3), ...
				'edgeColour', [0.1 0.1 0.1], ...
				'markerSize', 8, ...
				'lineWidth', 2);
			obj.Mobility = Mobility(Config.Mobility.scenario, 1, Config.Mobility.seed * userId, Config, obj.Logger, Layout);
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
			%TODO: make configureable in a proper way
			obj.Pmax = 10;
    end
		
		function s = struct(obj)
			% Struct needed for MATLAB LTE Library functions.
			s = struct(...
				'NCellID', obj.NCellID, ...
				'NULRB', obj.NULRB, ... 
				'NSubframe', obj.NSubframe, ...
				'NFrame', obj.NFrame, ...
				'RNTI', obj.RNTI, ...
				'NTxAnts', obj.NTxAnts, ...
				'PUSCH', obj.Tx.PUSCH);
		end

		function obj = move(obj, round)
			obj.Position(1:3) = obj.Mobility.Trajectory(round+1,:);
		end
		
		% Reset the HARQ report
		function obj = resetHarqReport(obj)
			obj.Mac.HarqReport = struct('pid', [0 0 0], 'ack', -1);
		end

		function obj = generateTransportBlockDL(obj, Cells, Config, timeNow)
			% generateTransportBlockDL is used to create a TB with dummy data for the UE
			%
			% :param obj: UserEquipment instance
			% :param Cells: Array<EvolvedNodeB> instances
			% :param Config: MonsterConfig instance
			% :param timeNow: Int current simulation time
			% :returns obj: UserEquipment instance
			%

			% Get the current serving Cell for this UE
			enbObjHandle = Cells([Cells.NCellID] == obj.ENodeBID);

			% Convert the relevant attributes to struct to allow local modification of fields
			enb = struct(enbObjHandle);
			pdsch = enbObjHandle.Tx.PDSCH;

			% Find the schedule of this UE in the eNodeB

			ueScheduleIndexes = enbObjHandle.getPRBSetDL(obj);

			numPrb = length(ueScheduleIndexes);
			if numPrb > 0 

				% the TB is created of a size that matches the allocation that the 
				% PDSCH symbols will have on the grid and the rate matching for the CW
				pdsch.Modulation = enbObjHandle.getModulationDL(obj);
				pdsch.PRBSet = (ueScheduleIndexes - 1).';	
				[~,info] = ltePDSCHIndices(enb, pdsch, pdsch.PRBSet);
				TbInfo.rateMatch = info.G;
				% the redundacy version (RV) is defaulted to 0
				TbInfo.rv = 0;
				% Finally, we need to calculate the TB size given the scheduling
				TbInfo.tbSize = lteTBS(numPrb, enbObjHandle.getMCSDL(obj));

				% Encode the SQN and the HARQ process ID into the TB if retransmissions are on
				% Use the first 13 bits for that. 
				% The first 3 are the HARQ PID, the other 10 are the SQN.
				if Config.Harq.active
					% get the SQN: start by searching whether this is a TB 
					% that is already being transmitted and is already in the RLC buffer
					% perform this on the handle as the values need to be updated in the main object
					iArqBuf = find([enbObjHandle.Rlc.ArqTxBuffers.rxId] == obj.NCellID);
					[enbObjHandle.Rlc.ArqTxBuffers(iArqBuf), sqnDec] = getNextSqn(enbObjHandle.Rlc.ArqTxBuffers(iArqBuf));
					sqnBin = de2bi(sqnDec, 10, 'left-msb')';

					% get the HARQ PID: find the index of the process
					iHarqProc = find([enbObjHandle.Mac.HarqTxProcesses.rxId] == obj.NCellID);
					% Find pid
					[enbObjHandle.Mac.HarqTxProcesses(iHarqProc), harqPidDec, newTb] = findProcess(enbObjHandle.Mac.HarqTxProcesses(iHarqProc), sqnDec);	
					harqPidBin = de2bi(harqPidDec, 3, 'left-msb')';
	
					% Create the control bits sequence 
					ctrlBits = cat(1, harqPidBin, sqnBin);
					tbPayload = randi([0 1], TbInfo.tbSize - length(ctrlBits), 1);
					tb = cat(1, ctrlBits, tbPayload);
					if newTb
						% Set TB in the ARQ buffer
						enbObjHandle.Rlc.ArqTxBuffers(iArqBuf) = enbObjHandle.Rlc.ArqTxBuffers(iArqBuf).handleTbInsert(sqnDec, timeNow, tb);	

						% Set TB in the HARQ process
						enbObjHandle.Mac.HarqTxProcesses(iHarqProc) = enbObjHandle.Mac.HarqTxProcesses(iHarqProc).handleTbInsert(harqPidDec, timeNow, tb);	
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

		function obj = generateCodewordDL(obj)
			% generateCodewordDL creates a codeword from a TB
			% 
			% :param obj: UserEquipment instance
			% :returns obj: UserEquipment instance
			%
			if ~isempty(obj.TransportBlock)
				% perform CRC encoding with 24A poly
				encTB = lteCRCEncode(obj.TransportBlock, '24A');

				% create code block segments
				cbs = lteCodeBlockSegment(encTB);

				% turbo-encoding of cbs
				turboEncCbs = lteTurboEncode(cbs);

				% finally rate match and return codeword
				cwd = lteRateMatchTurbo(turboEncCbs, obj.TransportBlockInfo.rateMatch, obj.TransportBlockInfo.rv);

				obj.Codeword = cwd;
			else
				obj.Codeword = [];
			end
		end

		function obj = downlinkReception(obj, Cells, ChannelEstimator)
			% downlinkReception is used to handle the reception and demodulation of a DL waveform
			%
			% :obj: UserEquipment instance
			% :Cells: Array<EvolvedNodeB>
			% :ChannelEstimator: Channel.Estimator property 
			%

			% Get the current serving Cell for this UE
			enb = Cells([Cells.NCellID] == obj.ENodeBID);
			obj.Rx.receiveDownlink(enb, ChannelEstimator);	
		end

		function obj = downlinkDataDecoding(obj, Config, timeNow)
			% downlinkDataDecoding performs the decoding of the demodulated waveform
			% 
			% :param obj: UserEquipment instance
			% :param Config: MonsterConfig instance
			% :param timeNow: Int current simulation time
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
					[obj.Mac.HarqRxProcesses, state] = obj.Mac.HarqRxProcesses.handleTbReception(iProc,obj.Rx.TransportBlock, obj.Rx.Crc, timeNow);

					% Depending on the state the process is, contact ARQ
					if state == 0
						sqn = obj.Rlc.ArqRxBuffer.decodeSqn(obj.Rx.TransportBlock);
						if ~isempty(sqn)
							obj.Rlc.ArqRxBuffer = obj.Rlc.ArqRxBuffer.handleTbReception(sqn, obj.Rx.TransportBlock, timeNow, obj.Logger);
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

		function obj = reset(obj)
			% reset is used to clean up the instance before another round
			%
			% :param obj: UserEquipment instance
			% :returns obj: UserEquipment instance
			%
			
			obj.Scheduled = struct('DL', false, 'UL', false);
			obj.Symbols = [];
			obj.SymbolsInfo = [];
			obj.Codeword = [];
			obj.CodewordInfo = [];
			obj.TransportBlock = [];
			obj.TransportBlockInfo = [];
			obj.Tx = obj.Tx.reset();
			obj.Rx = obj.Rx.reset();
		end
		
	end	
end
