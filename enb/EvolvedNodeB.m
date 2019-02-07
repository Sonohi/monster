classdef EvolvedNodeB < matlab.mixin.Copyable
	%   EVOLVED NODE B defines a value class for creating and working with eNodeBs
	properties
		NCellID;
		DuplexMode;
		Position;
		NDLRB;
		CellRefP;
		CyclicPrefix;
		CFI;
		DlFreq;
		PHICHDuration;
		Ng;
		TotSubframes;
		OCNG;
		Windowing;
		Users = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
		ScheduleDL;
		ScheduleUL;
		RoundRobinDLNext;
		RoundRobinULNext;
		Channel;
		NSubframe;
		BsClass;
		PowerState;
		Neighbours;
		HystCount;
		SwitchCount;
		Pmax;
		P0;
		DeltaP;
		Psleep;
		Tx;
		Rx;
		Mac;
		Rlc;
		Seed;
		AbsMask;
		PowerIn;
		ShouldSchedule;
		Utilisation;
	end
	
	methods
		% Constructor
		function obj = EvolvedNodeB(Config, BsClass, cellId)
			switch BsClass
				case 'macro'
					obj.NDLRB = Config.MacroEnb.subframes;
					obj.Pmax = 20; % W
					obj.P0 = 130; % W
					obj.DeltaP = 4.7;
					obj.Psleep = 75; % W
				case 'micro'
					obj.NDLRB = Config.MicroEnb.subframes;
					obj.Pmax = 6.3; % W
					obj.P0 = 56; % W
					obj.DeltaP = 2.6;
					obj.Psleep = 39.0; % W
				case 'pico'
					obj.NDLRB = Config.PicoEnb.subframes;
					obj.Pmax = 0.13; % W
					obj.P0 = 6.8; % W
					obj.DeltaP = 4.0;
					obj.Psleep = 4.3; % W
			end
			obj.BsClass = BsClass;
			obj.NCellID = cellId;
			obj.Seed = cellId*Config.Runtime.seed;
			obj.CellRefP = 1;
			obj.CyclicPrefix = 'Normal';
			obj.CFI = 1;
			obj.PHICHDuration = 'Normal';
			obj.Ng = 'Sixth';
			obj.TotSubframes = Config.Runtime.totalRounds;
			obj.NSubframe = 0;
			obj.OCNG = 'On';
			obj.Windowing = 0;
			obj.DuplexMode = 'FDD';
			obj.RoundRobinDLNext = struct('UeId',0,'Index',1);
			obj.RoundRobinULNext = struct('UeId',0,'Index',1);
			obj = resetScheduleDL(obj);
			obj.ScheduleUL = [];
			obj.PowerState = 1;
			obj.Neighbours = zeros(1, Config.MacroEnb.number + Config.MicroEnb.number + Config.PicoEnb.number - 1);
			obj.HystCount = 0;
			obj.SwitchCount = 0;
			obj.DlFreq = Config.Phy.downlinkFrequency;
			if Config.Harq.active
				obj.Mac = struct('HarqTxProcesses', arrayfun(@(x) HarqTx(0, cellId, x, Config), 1:Config.Ue.number));
				obj.Rlc = struct('ArqTxBuffers', arrayfun(@(x) ArqTx(cellId, x), 1:Config.Ue.number));
			end
			obj.Tx = enbTransmitterModule(obj, Config);
			obj.Rx = enbReceiverModule(obj, Config);
			obj.Users(1:Config.Ue.number) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
			obj.AbsMask = Config.Scheduling.absMask; % 10 is the number of subframes per frame. This is the mask for the macro (0 == TX, 1 == ABS)
			obj.PowerIn = 0;
			obj.ShouldSchedule = 0;
			obj.Utilisation = 0;
			% Should look up position based on class here, not outside
			
		end
		
		function s = struct(obj)
			% Overwrites struct on object. Used primarly for lte Library methods of Matlab.
			s = struct();
			s.NDLRB = obj.NDLRB;
			s.CellRefP = obj.CellRefP;
			s.NCellID = obj.NCellID;
			s.NSubframe = obj.NSubframe;
			s.CFI = obj.CFI;
			s.Ng = obj.Ng;
			s.CyclicPrefix = obj.CyclicPrefix;
			s.PHICHDuration = obj.PHICHDuration;
			s.DuplexMode = obj.DuplexMode;
		end
		
		function TxPw = getTransmissionPower(obj)
			% TODO: Move this to TransmitterModule?
			% Function computes transmission power based on NDLRB
			% Return power per subcarrier. (OFDM symbol)
			total_power = obj.Pmax;
			TxPw = total_power/(12*obj.NDLRB);
		end
		
		% reset users
		function obj = resetUsers(obj, Config)
			obj.Users(1:Config.Ue.number) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
		end
		
		% reset schedule
		function obj = resetScheduleDL(obj)
			temp(1:obj.NDLRB,1) = struct('UeId', -1, 'Mcs', -1, 'ModOrd', -1, 'NDI', 1);
			obj.ScheduleDL = temp;
		end
		
		function obj = resetScheduleUL(obj)
			obj.ScheduleUL = [];
		end
		
		function [indPdsch, info] = getPDSCHindicies(obj)
			enb = struct(obj);
			% get PDSCH indexes
			[indPdsch, info] = ltePDSCHIndices(enb, enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
		end
		
		% create list of neighbours
		function obj = setNeighbours(obj, Stations, Config)
			% the macro eNodeB has neighbours all the micro
			if strcmp(obj.BsClass,'macro')
				obj.Neighbours(1:Config.MicroEnb.number + Config.PicoEnb.number) = find([Stations.NCellID] ~= obj.NCellID);
				% the micro eNodeBs only get the macro as neighbour and all the micro eNodeBs
				% in a circle of radius Config.Son.neighbourRadius
			else
				for iStation = 1:length(Stations)
					if strcmp(Stations(iStation).BsClass, 'macro')
						% insert in array at lowest index with 0
						ix = find(not(obj.Neighbours), 1 );
						obj.Neighbours(ix) = Stations(iStation).NCellID;
					elseif Stations(iStation).NCellID ~= obj.NCellID
						pos = obj.Position(1:2);
						nboPos = Stations(iStation).Position(1:2);
						dist = pdist(cat(1, pos, nboPos));
						if dist <= Config.Son.neighbourRadius
							ix = find(not(obj.Neighbours), 1 );
							obj.Neighbours(ix) = Stations(iStation).NCellID;
						end
					end
				end
			end
		end
		
		function obj = generateSymbols(obj, Users)
			% generateSymbols
			%
			% :param obj: EvolvedNodeB instance
			% :param Users: UserEquipment instances
			% :returns obj: EvolvedNodeB instance
			%
			
			% Filter the overall list of Users and only take those associated
			% with this eNodeB
			enbUsers = Users(find([Users.ENodeBID] == obj.NCellID));
			for iUser = 1:length(enbUsers)
				ue = enbUsers(iUser);
				% Check for empty codewords
				if ~isempty(ue.Codeword)
					% find all the PRBs assigned to this UE to find the most conservative MCS (min)
					sch = obj.ScheduleDL;
					ixPRBs = find([sch.UeId] == ue.NCellID);
					if ~isempty(ixPRBs)
						listMCS = [sch(ixPRBs).Mcs];
						
						% get the correct Parameters for this UE
						[~, mod, ~] = lteMCS(min(listMCS));
						
						% get the codeword
						cwd = ue.Codeword;
						
						% setup the PDSCH for this UE
						obj.Tx.PDSCH.Modulation = mod;	% conservative modulation choice from above
						obj.Tx.PDSCH.PRBSet = (ixPRBs - 1).';	% set of assigned PRBs
						
						% Get info and indexes
						[pdschIxs, SymInfo] = ltePDSCHIndices(struct(obj), obj.Tx.PDSCH, obj.Tx.PDSCH.PRBSet);
						
						if length(cwd) ~= SymInfo.G
							% In this case seomthing went wrong with the rate maching and in the
							% creation of the codeword, so we need to flag it
							monsterLog('(EVOLVED NODE B - generateSymbols) Something went wrong in the codeword creation and rate matching. Size mismatch','WRN');
						end
						
						% error handling for symbol creation
						try
							sym = ltePDSCH(struct(obj), obj.Tx.PDSCH, cwd);
						catch ME
							fSpec = '(EVOLVED NODE B - generateSymbols) generation failed for codeword with length %i\n';
							s=sprintf(fSpec, length(cwd));
							monsterLog(s,'WRN')
							sym = [];
						end
						
						SymInfo.symSize = length(sym);
						SymInfo.pdschIxs = pdschIxs;
						SymInfo.indexes = ixPRBs;
						ue.SymbolsInfo = SymInfo;
						
						% Set the symbols into the grid of the eNodeB
						obj.Tx.setPDSCHGrid(sym);
					else
						SymInfo = struct();
						SymInfo.symSize = 0;
						SymInfo.pdschIxs = [];
						SymInfo.indexes = [];
						ue.SymbolsInfo = SymInfo;
					end
				end
			end
		end
		
		function userIds = getUserIDsScheduledDL(obj)
			userIds = unique([obj.ScheduleDL]);
		end
		
		function userIds = getUserIDsScheduledUL(obj)
			userIds = unique([obj.ScheduleUL]);
		end
		
		function obj = evaluatePowerState(obj, Config, Stations)
			% evaluatePowerState checks the utilisation of an EvolvedNodeB to evaluate the power state
			%
			% :obj: EvolvedNodeB instance
			% :Config: MonsterConfig instance
			% :Stations: Array<EvolvedNodeB> instances in case neighbours are needed
			%
			
			% overload
			if obj.Utilisation > Config.Son.utilHigh && Config.Son.utilHigh ~= 100
				obj.PowerState = 2;
				obj.HystCount = obj.HystCount + 1;
				if obj.HystCount >= Config.Son.hysteresisTimer/10^-3
					% The overload has exceeded the hysteresis timer, so find an inactive
					% neighbour that is micro to activate
					nboMicroIxs = find([obj.Neighbours] ~= Stations(1).NCellID);
					
					% Loop the neighbours to find an inactive one
					for iNbo = 1:length(nboMicroIxs)
						if nboMicroIxs(iNbo) ~= 0
							% find this neighbour in the stations
							nboIx = find([Stations.NCellID] == obj.Neighbours(nboMicroIxs(iNbo)));
							
							% Check if it can be activated
							if (~isempty(nboIx) && Stations(nboIx).PowerState == 5)
								% in this case change the PowerState of the target neighbour to "boot"
								% and reset the hysteresis and the switching on/off counters
								Stations(nboIx).PowerState = 6;
								Stations(nboIx).HystCount = 0;
								Stations(nboIx).SwitchCount = 0;
								break;
							end
						end
					end
				end
				
				% underload, shutdown, inactive or boot
			elseif obj.Utilisation < Config.Son.utilLow && Config.Son.utilLow ~= 1
				switch obj.PowerState
					case 1
						% eNodeB active and going in underload for the first time
						obj.PowerState = 3;
						obj.HystCount = 1;
					case 3
						% eNodeB already in underload
						obj.HystCount = obj.HystCount + 1;
						if obj.HystCount >= Config.Son.hysteresisTimer/10^-3
							% the underload has exceeded the hysteresis timer, so start switching
							obj.PowerState = 4;
							obj.SwitchCount = 1;
						end
					case 4
						obj.SwitchCount = obj.SwitchCount + 1;
						if obj.SwitchCount >= Config.Son.hysteresisTimer/10^-3
							% the shutdown is completed
							obj.PowerState = 5;
							obj.SwitchCount = 0;
							obj.HystCount = 0;
						end
					case 6
						obj.SwitchCount = obj.SwitchCount + 1;
						if obj.SwitchCount >= Config.Son.switchTimer/10^-3
							% the boot is completed
							obj.PowerState = 1;
							obj.SwitchCount = 0;
							obj.HystCount = 0;
						end
				end
				
				% normal operative range
			else
				obj.PowerState = 1;
				obj.HystCount = 0;
				obj.SwitchCount = 0;
				
			end
		end
		
		% set uplink static scheduling
		function obj = setScheduleUL(obj, Config)
			% Check the number of users associated with the eNodeB and initialise to all
			associatedUEs = find([obj.Users.UeId] ~= -1);
			% If the quota of PRBs is enough for all, then all are scheduled
			if ~isempty(associatedUEs)
				prbQuota = floor(Config.Ue.subframes/length(associatedUEs));
				% Check if the quota is not below 6, in such case we need to rotate the users
				if prbQuota < 6
					% In this case the maximum quota is 6 so we need to save the first UE not scheduled
					prbQuota = 6;
					ueMax = floor(Config.Ue.subframes/prbQuota);
					% Now extract ueMax from the associatedUEs array, starting from the latest un-scheduled one
					iMax = obj.RoundRobinULNext.Index + ueMax - 1;
					iDiff = 0;
					% Check that the upper bound does not exceed the length, if that's the case just restart
					if iMax > length(associatedUEs)
						iDiff = iMax - length(associatedUEs);
						iMax = length(associatedUEs);
					end
					% Now extract 2 arrays from the associatedUEs and concatenate them
					firstSlice = associatedUEs(obj.RoundRobinULNext.Index : iMax);
					if iDiff ~= 0
						secondSlice = associatedUEs(1:iDiff);
					else
						secondSlice = [];
					end
					finalSlice = cat(2, firstSlice, secondSlice);
					% Finally, store the ID and the index of the first UE that has not been scheduled this round
					iNext = iMax + 1;
					if iNext > length(associatedUEs)
						iNext = 1;
					end
					% Now get the ID an the index relative to the overall Users array
					obj.RoundRobinULNext.UeId = obj.Users(associatedUEs(iNext)).UeId;
					obj.RoundRobinULNext.Index = find([obj.Users.UeId] == obj.RoundRobinULNext.UeId);
					% ensure uniqueness
					associatedUEs = extractUniqueIds(finalSlice);
				else
					% In this case, all connected UEs can be scheduled, so RR can be reset
					obj.RoundRobinULNext = struct('UeId',0,'Index',1);
				end
				prbAvailable = Config.Ue.subframes;
				scheduledUEs = zeros(length(associatedUEs)*prbQuota, 1);
				for iUser = 1:length(associatedUEs)
					if prbAvailable >= prbQuota
						iStart = (iUser - 1)*prbQuota;
						iStop = iStart + prbQuota;
						scheduledUEs(iStart + 1:iStop) = obj.Users(associatedUEs(iUser)).UeId;
						prbAvailable = prbAvailable - prbQuota;
					else
						monsterLog('Some UEs have not been scheduled in UL due to insufficient PRBs', 'NFO');
						break;
					end
				end
				obj.ScheduleUL = scheduledUEs;
			end
		end
		
		% used to calculate the power in based on the BS class
		function obj = calculatePowerIn(obj, enbCurrentUtil, otaPowerScale, utilLoThr)
			% The output power over the air depends on the utilisation, if energy saving is enabled
			if utilLoThr > 1
				Pout = obj.Pmax*enbCurrentUtil*otaPowerScale;
			else
				Pout = obj.Pmax;
			end
			
			% Now check power state of the eNodeB
			if obj.PowerState == 1 || obj.PowerState == 2 || obj.PowerState == 3
				% active, overload and underload state
				obj.PowerIn = obj.CellRefP*obj.P0 + obj.DeltaP*Pout;
			else
				% shutodwn, inactive and boot
				obj.PowerIn = obj.Psleep;
			end
		end
		
		% Reset an eNodeB at the end of a scheduling round
		function obj = reset(obj, nextSchRound)
			% First off, set the number of the next subframe within the frame
			% this is the scheduling round modulo 10 (the frame is 10ms)
			obj.NSubframe = mod(nextSchRound,10);
			
			% Reset the DL schedule
			obj = obj.resetScheduleDL();
			
			% Reset the transmitter
			obj.Tx.reset(nextSchRound);
			
			% Reset the receiver
			obj.Rx.reset();
			
		end
		
		function obj = evaluateScheduling(obj, Users)
			% evaluateScheduling sets the ShouldSchedule flag depending on attached UEs and their queues
			%
			% :obj: EvolvedNodeB instance
			% :Users: Array<UserEquipment> instances
			%
			
			schFlag = false;
			if ~isempty(find([obj.Users.UeId] ~= -1, 1))
				% There are users connected, filter them from the Users list and check the queue
				enbUsers = Users(find([Users.ENodeBID] == obj.NCellID));
				usersQueues = [enbUsers.Queue];
				if any([usersQueues.Size])
					% Now check the power status of the eNodeB
					if ~isempty(find([1, 2, 3] == obj.PowerState, 1))
						% Normal, underload and overload => the eNodeB can schedule
						schFlag = true;
					elseif ~isempty(find([4, 6] == obj.PowerState, 1))
						% The eNodeB is shutting down or booting up => the eNodeB cannot schedule
						schFlag = false;
					elseif enb.PowerState == 5
						% The eNodeB is inactive, but should be restarted
						obj.PowerState = 6;
						obj.SwitchCount = 0;
					end
				end
			end
			
			% Finally, assign the result of the scheduling check to the object property
			obj.ShouldSchedule = schFlag;
		end
		
		function obj = downlinkSchedule(obj, Users, Config)
			% downlinkSchedule is wrapper method for calling the scheduling function
			%
			% :obj: EvolvedNodeB instance
			% :Users: Array<UserEquipment> instances
			% :Config: MonsterConfig instance
			
			if obj.ShouldSchedule
				[obj, Users] = schedule(obj, Users, Config);
				% Check utilisation
				sch = find([obj.ScheduleDL.UeId] ~= -1);
				obj.Utilisation = 100*find(sch, 1, 'last' )/length([obj.ScheduleDL]);
				
				if isempty(obj.Utilisation)
					obj.Utilisation = 0;
				end
			else
				obj.Utilisation = 0;
			end
		end
		
		function obj = uplinkReception(obj, Users, timeNow, ChannelEstimator)
			% uplinkReception performs uplink demodulation and decoding
			%
			% :obj: EvolvedNodeB instance
			% :Users: Array<UserEquipment> UEs instances
			% :timeNow: Float current simulation time in seconds
			% :ChannelEstimator: Struct Channel.Estimator property
			%
			
			% If the eNodeB has an empty received waveform, skip it (no UEs associated)
			if isempty(obj.Rx.Waveform)
				monsterLog(sprintf('(EVOLVED NODE B - uplinkReception)eNodeB %i has an empty received waveform', obj.NCellID), 'NFO');
			else				
				% IDs of users and their position in the Users struct correspond
				scheduledUEsIndexes = [obj.ScheduleUL] ~= -1;
				scheduledUEsIds = unique(obj.ScheduleUL(scheduledUEsIndexes));
				enbUsers = Users(scheduledUEsIds);
				
				% Parse received waveform
				obj.Rx.parseWaveform(obj);
				
				% Demodulate received waveforms
				obj.Rx.demodulateWaveforms(enbUsers);
				
				% Estimate Channel
				obj.Rx.estimateChannels(enbUsers, ChannelEstimator);
				
				% Equalise
				obj.Rx.equaliseSubframes(enbUsers);
				
				% Estimate PUCCH (Main UL control channel) for UEs
				obj.Rx.estimatePucch(obj, enbUsers, timeNow);
				
				% Estimate PUSCH (Main UL control channel) for UEs
				%obj.Rx.estimatePusch(obj, enbUsers, timeNow);
			end
			
			
		end
		
		function obj = uplinkDataDecoding(obj, Users, Config)
			% uplinkDataDecoding performs decoding of the demodoulated data in the waveform
			%
			% :obj: EvolvedNodeB instance
			% :Users: Array<UserEquipment> UEs instances
			% :Config: MonsterConfig instance
			%
			
			% Filter UEs linked to this eNodeB
			timeNow = Config.Runtime.currentTime;
			ueGroup = find([Users.ENodeBID] == enb.NCellID);
			enbUsers = Users(ueGroup);
			
			for iUser = 1:length(obj.Rx.UeData)
				% If empty, no uplink UE data has been received in this round and skip
				if ~isempty(obj.Rx.UeData(iUser).PUCCH)
					cqiBits = obj.Rx.UeData(iUser).PUCCH(12:16,1);
					cqi = bi2de(cqiBits', 'left-msb');
					ueEnodeBIx= find([obj.Users.UeId] == obj.Rx.UeData(iUser).UeId);
					if ~isempty(ueEnodeBIx)
						obj.Users(ueEnodeBIx).CQI = cqi;
					end
					
					if Config.Harq.active
						% Decode HARQ feedback
						[harqPid, harqAck] = obj.Mac.HarqTxProcesses(harqIndex).decodeHarqFeedback(obj.Rx.UeData(iUser).PUCCH);
						
						if ~isempty(harqPid)
							[obj.Mac.HarqTxProcesses(harqIndex), state, sqn] = obj.Mac.HarqTxProcesses(harqIndex).handleReply(harqPid, harqAck, timeNow, Config);
							
							% Contact ARQ based on the feedback
							if Config.Arq.active && ~isempty(sqn)
								arqIndex = find([obj.Rlc.ArqTxBuffers.rxId] == obj.Rx.UeData(iUser).UeId);
								
								if state == 0
									% The process has been acknowledged
									obj.Rlc.ArqTxBuffers(arqIndex) = obj.Rlc.ArqTxBuffers(arqIndex).handleAck(1, sqn, timeNow, Config);
								elseif state == 4
									% The process has failed
									obj.Rlc.ArqTxBuffers(arqIndex) = obj.Rlc.ArqTxBuffers(arqIndex).handleAck(0, sqn, timeNow, Config);
								else
									% No action to be taken by ARQ
								end
							end
						end
					end
				end
			end
		end
		
	end
end
