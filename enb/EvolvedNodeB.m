classdef EvolvedNodeB
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
	end
	
	methods
		% Constructor
		function obj = EvolvedNodeB(Param, BsClass, cellId)
			switch BsClass
				case 'macro'
					obj.NDLRB = Param.numSubFramesMacro;
					obj.Pmax = 20; % W
					obj.P0 = 130; % W
					obj.DeltaP = 4.7;
					obj.Psleep = 75; % W
				case 'micro'
					obj.NDLRB = Param.numSubFramesMicro;
					obj.Pmax = 6.3; % W
					obj.P0 = 56; % W
					obj.DeltaP = 2.6;
					obj.Psleep = 39.0; % W
				case 'pico'
					obj.NDLRB = Param.numSubFramesPico;
					obj.Pmax = 0.13; % W
					obj.P0 = 6.8; % W
					obj.DeltaP = 4.0;
					obj.Psleep = 4.3; % W
			end
			obj.BsClass = BsClass;
			obj.NCellID = cellId;
			obj.Seed = cellId*Param.seed;
			obj.CellRefP = 1;
			obj.CyclicPrefix = 'Normal';
			obj.CFI = 1;
			obj.PHICHDuration = 'Normal';
			obj.Ng = 'Sixth';
			obj.TotSubframes = Param.schRounds;
			obj.NSubframe = 0;
			obj.OCNG = 'On';
			obj.Windowing = 0;
			obj.DuplexMode = 'FDD';
			obj.RoundRobinDLNext = struct('UeId',0,'Index',1);
			obj.RoundRobinULNext = struct('UeId',0,'Index',1);
			obj = resetScheduleDL(obj);
			obj.ScheduleUL = [];
			obj.PowerState = 1;
			obj.Neighbours = zeros(1, Param.numEnodeBs);
			obj.HystCount = 0;
			obj.SwitchCount = 0;
			obj.DlFreq = Param.dlFreq;
			if Param.rtxOn
				obj.Mac = struct('HarqTxProcesses', harqTxBulk(Param, cellId, 1:Param.numUsers, 0));
				obj.Rlc = struct('ArqTxBuffers', arqTxBulk(Param, cellId, 1:Param.numUsers, 0));
			end
			obj.Tx = enbTransmitterModule(obj, Param);
			obj.Rx = enbReceiverModule(Param);
			obj.Users(1:Param.numUsers) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
			obj.AbsMask = Param.absMask; % 10 is the number of subframes per frame. This is the mask for the macro (0 == TX, 1 == ABS)
			obj.PowerIn = 0;
    end
		
    function TxPw = getTransmissionPower(obj)
      % TODO: Move this to TransmitterModule?
      % Function computes transmission power based on NDLRB
      % Return power per subcarrier. (OFDM symbol)
      total_power = obj.Pmax;
      TxPw = total_power/(12*obj.NDLRB);
    end
    
		% Position eNodeB
		function obj = setPosition(obj, pos)
			obj.Position = pos;
		end
		
		% reset users
		function obj = resetUsers(obj, Param)
			obj.Users(1:Param.numUsers) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
		end
		
		% reset schedule
		function obj = resetScheduleDL(obj)
			temp(1:obj.NDLRB,1) = struct('UeId', -1, 'Mcs', -1, 'ModOrd', -1, 'NDI', 1);
			obj.ScheduleDL = temp;
		end
		
		function obj = resetScheduleUL(obj)
			obj.ScheduleUL = [];
		end
		
		% set subframe number
		function obj = set.NSubframe(obj, num)
			obj.NSubframe = num;
		end
		
		function [indPdsch, info] = getPDSCHindicies(obj)
			enb = cast2Struct(obj);
			% get PDSCH indexes
			[indPdsch, info] = ltePDSCHIndices(enb, enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
		end
		
		% create list of neighbours
		function obj = setNeighbours(obj, Stations, Param)
			% the macro eNodeB has neighbours all the micro
			if strcmp(obj.BsClass,'macro')
				obj.Neighbours(1:Param.numMicro + Param.numPico) = find([Stations.NCellID] ~= obj.NCellID);
				% the micro eNodeBs only get the macro as neighbour and all the micro eNodeBs
				% in a circle of radius Param.nboRadius
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
						if dist <= Param.nboRadius
							ix = find(not(obj.Neighbours), 1 );
							obj.Neighbours(ix) = Stations(iStation).NCellID;
						end
					end
				end
			end
		end
		
		% check utilisation wrapper
		function obj = evaluatePowerState(obj, util, Param, loThr, hiThr, Stations)
			% overload
			if util > hiThr && hiThr ~= 100
				obj.PowerState = 2;
				obj.HystCount = obj.HystCount + 1;
				if obj.HystCount >= Param.tHyst/10^-3
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
			elseif util < loThr && loThr ~= 1
				switch obj.PowerState
					case 1
						% eNodeB active and going in underload for the first time
						obj.PowerState = 3;
						obj.HystCount = 1;
					case 3
						% eNodeB already in underload
						obj.HystCount = obj.HystCount + 1;
						if obj.HystCount >= Param.tHyst/10^-3
							% the underload has exceeded the hysteresis timer, so start switching
							obj.PowerState = 4;
							obj.SwitchCount = 1;
						end
					case 4
						obj.SwitchCount = obj.SwitchCount + 1;
						if obj.SwitchCount >= Param.tSwitch/10^-3
							% the shutdown is completed
							obj.PowerState = 5;
							obj.SwitchCount = 0;
							obj.HystCount = 0;
						end
					case 6
						obj.SwitchCount = obj.SwitchCount + 1;
						if obj.SwitchCount >= Param.tSwitch/10^-3
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
		
		% cast object to struct
		function enbStruct = cast2Struct(obj)
			enbStruct = struct(obj);
		end
		
		% set uplink static scheduling
		function obj = setScheduleUL(obj, Param)
			% Check the number of users associated with the eNodeB and initialise to all
			associatedUEs = find([obj.Users.UeId] ~= -1);
			% If the quota of PRBs is enough for all, then all are scheduled
			if ~isempty(associatedUEs)
				prbQuota = floor(Param.numSubFramesUE/length(associatedUEs));
				% Check if the quota is not below 6, in such case we need to rotate the users
				if prbQuota < 6
					% In this case the maximum quota is 6 so we need to save the first UE not scheduled
					prbQuota = 6;
					ueMax = floor(Param.numSubFramesUE/prbQuota);
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
				prbAvailable = Param.numSubFramesUE;
				scheduledUEs = zeros(length(associatedUEs)*prbQuota, 1);
				for iUser = 1:length(associatedUEs)
					if prbAvailable >= prbQuota
						iStart = (iUser - 1)*prbQuota;
						iStop = iStart + prbQuota;
						scheduledUEs(iStart + 1:iStop) = obj.Users(associatedUEs(iUser)).UeId;
						prbAvailable = prbAvailable - prbQuota;
					else
						sonohilog('Some UEs have not been scheduled in UL due to insufficient PRBs', 'INFO');
						break;
					end
				end
				obj.ScheduleUL = scheduledUEs;
			end
		end

		% Used to initiate the reboot of an eNodeB by traffic demand
		function obj = initiateBoot(obj)
			obj.PowerState = 6;
			obj.SwitchCount = 0;
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
			obj.Tx = obj.Tx.reset(obj, nextSchRound);
			
			% Reset the receiver
			obj.Rx = obj.Rx.reset();
			
		end
		
	end
	
end
