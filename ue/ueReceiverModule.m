classdef ueReceiverModule < matlab.mixin.Copyable
	properties
		NoiseFigure;
		EstChannelGrid;
		NoiseEst;
		RSSIdBm;
		RSRQdB;
		RSRPdBm;
		SINR;
		SINRdB;
		SNR;
		SNRdB;
		Waveform;
  	WaveformInfo;
		RxPwdBm; % Wideband
		PathGains; % Used for perfect synchronization
		PathFilters; % Used for perfect synchronization;
		Subframe;
		EqSubframe;
		TransportBlock;
		Crc;
		PreEvm;
		PostEvm;
		CQI;
		Offset;
		BLER;
		Throughput;
		SchIndexes;
		Blocks;
		Bits;
		PDSCH;
		PropDelay;
		HistoryStats;
		SINRS;
		Demod;
		AntennaArray;
		ueObj; % Parent UE handle
	end

	properties (Access = private)
		PerfectSynchronization;
	end
	
	methods
		
		function obj = ueReceiverModule(ueObj, Config)
			obj.Offset = 0;
			obj.ueObj = ueObj;
			obj.NoiseFigure = Config.Ue.noiseFigure;
			obj.CQI = 3;
			obj.Blocks = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Bits = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.PerfectSynchronization = Config.Channel.perfectSynchronization;
			obj.AntennaArray = AntennaArray(Config.Ue.antennaType, Config.Phy.downlinkFrequency*10e5);
		end
		
		function loss = getLoss(obj, TxPosition, RxPosition)
			% Get loss of receiver module by combining noise figure with gain from antenna element
			% In the case of an ideal omni directional (isotropic) antenna the loss is equal to the noise figure
			AntennaGain = obj.AntennaArray.getAntennaGains(TxPosition, RxPosition);
			loss = obj.NoiseFigure + AntennaGain{1};
		end

		function oldValues = getFromHistory(obj, field, stationID)
			stationfield = strcat('NCellID',int2str(stationID));
			path = {'HistoryStats', stationfield, field};
			oldValues = getfield(obj, path{:});
		end
		
		function obj = addToHistory(obj, field, stationID)
			oldValues = obj.getFromHistory(field, stationID);
			stationfield = strcat('NCellID',int2str(stationID));
			path = {'HistoryStats', stationfield, field};
			newValue = getfield(obj, field);
			newArray = [oldValues, newValue];
			obj = setfield(obj, path{:}, newArray);		
		end
		
		
		function obj = set.SINR(obj,SINR,stationID)
			% SINR given linear
			obj.SINR = SINR;
			obj.SINRdB = 10*log10(SINR);
		end
		
		function obj = set.SNR(obj,SNR)
			% SNR given linear
			obj.SNR = SNR;
			obj.SNRdB = 10*log10(SNR);
		end
			
		function obj = set.PropDelay(obj,distance)
			obj.PropDelay = distance/physconst('LightSpeed');
		end

		function obj = receiveDownlink(obj, enb, cec)
			% Apply the receiver chain for subframe recovery
			
			% Find synchronization, apply offset
			obj.applyOffset(enb);
			
			% Conduct reference measurements
			obj.referenceMeasurements(enb);

			% If UE is not scheduled reset the metrics for the round
			if length(enb.getPRBSetDL(obj.ueObj)) <= 0
				obj.logNotScheduled();
			end
			
			% Demodulate waveform
			obj.demodulateWaveform(enb);
			
			if obj.Demod 
				% Estimate the channel
				obj.estimateChannel(enb, cec);
				
				% Apply equalization
				obj.equaliseSubframe();
				
				% Select CQI
				obj.selectCqi(enb);

				% Extract PDSCH
				obj.estimatePdsch(obj.ueObj, enb);

				% Calculate EVM
				obj.calculateEvm(enb);

				% Log block reception
				obj.logBlockReception(obj.ueObj);
			else
				monsterLog(sprintf('(USER EQUIPMENT - downlinkReception) not able to demodulate Station(%i) -> User(%i)...',enb.NCellID, obj.NCellID),'WRN');
				obj.logNotDemodulated();
				obj.CQI = 3;

			end
			% TODO: Select PMI, RI
		end
		
		function demodulateWaveform(obj,enbObj)
			% TODO: validate that a waveform exist.
			enb = struct(enbObj);
			Subframe = lteOFDMDemodulate(enb, obj.Waveform); %#ok
			
			if all(Subframe(:) == 0) %#ok
				obj.Demod = 0;
			else
				obj.Subframe = Subframe; %#ok
				obj.Demod = 1;
			end
		end
		
		% estimate channel at the receiver
		function obj = estimateChannel(obj, enbObj, cec)
			enb = struct(enbObj);
			[obj.EstChannelGrid, obj.NoiseEst] = lteDLChannelEstimate(enb, cec, obj.Subframe);
		end
		
		% equalize at the receiver
		function obj = equaliseSubframe(obj)
			obj.EqSubframe = lteEqualizeMMSE(obj.Subframe, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		function obj = estimatePdsch(obj, ue, enbObjHandle)
			% first get the PRBs that where used for the UE with this receiver
			obj.SchIndexes = enbObjHandle.getPRBSetDL(ue);
			if ~isempty(obj.SchIndexes)
				% Store the full PRB set for extraction
				fullPrbSet = enbObjHandle.Tx.PDSCH.PRBSet;
				
				% Create local copy for modifications
				enb = struct(enbObjHandle);
				pdschConfig = enbObjHandle.Tx.PDSCH;
				
				% To find which received PDSCH symbols belong to this UE, we need to
				% compute indexes for all other UEs allocated in this eNodeB, except
				% when the UE we are dealing with is the first one in the order that
				% does not have offset
				offset = 1;
				if obj.SchIndexes(1) ~= 1
					% extract the unique UE IDs from the schedule
					uniqueIds = extractUniqueIds([enb.ScheduleDL.UeId]);
					for iUser = 1:length(uniqueIds)
						if uniqueIds(iUser) ~= ue.NCellID
							% get all the PRBs assigned to this UE and continue only if it's slotted before the current UE
							prbIndices = find([enbObjHandle.ScheduleDL.UeId] == uniqueIds(iUser));
							if prbIndices(1) < obj.SchIndexes(1)
								[~, mod, ~] = lteMCS(enbObjHandle.ScheduleDL(prbIndices(1)).Mcs);
								pdschConfig.Modulation = mod;
								pdschConfig.PRBSet = (prbIndices - 1).';
								uePdschIndices = ltePDSCHIndices(enb, pdschConfig, pdschConfig.PRBSet);
								offset = offset + length(uePdschIndices);
							end
						end
					end
				end
				
				% Set the parameters of the PDSCH to those of the current UE
				mod = enbObjHandle.getModulationDL(ue);
				pdschConfig.Modulation = mod;
				pdschConfig.PRBSet = (obj.SchIndexes - 1).';
				
				% Now get all the PDSCH indexes and symbols out of the received grid
				% TODO for some reasons the built-in functions only work properly with the whole PDSCH
				fullPdschIndices = ltePDSCHIndices(enb, pdschConfig, fullPrbSet);
				[fullPdschRx, ~] = lteExtractResources(fullPdschIndices, obj.EqSubframe);
				
				% Filter out the PDSCH symbols and bits that are meant for this receiver.
				% The indices obtained with the function refer to positions in the main grid
				uePdschIndices = ue.SymbolsInfo.pdschIxs;
				uePdschRx = fullPdschRx(offset:offset + length(uePdschIndices) - 1);
				
				% Decode PDSCH
				[ueDlsch, uePdsch] = ltePDSCHDecode(enb, pdschConfig, uePdschRx);
				uePdsch = uePdsch{1};
				ueDlsch = ueDlsch{1};
				
				% The decoded DL-SCH bits are always returned as a cell array, so for 1 CW
				% cases convert it
				obj.PDSCH = uePdsch;
				% Decode DL-SCH
				[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, pdschConfig, ue.TransportBlockInfo.tbSize, ueDlsch);
			end
		end
		
		% calculate the EVM
		function obj = calculateEvm(obj, enbObj)
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PreEvm = EVM(enbObj.Tx.ReGrid,obj.Subframe);
			s = sprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', obj.PreEvm);
			monsterLog(s,'NFO0')
			
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PostEvm = EVM(enbObj.Tx.ReGrid,obj.EqSubframe);
			s = sprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', obj.PostEvm);
			monsterLog(s,'NFO0')
		end
		
		% select CQI
		function obj = selectCqi(obj, enbObj)
			enb = struct(enbObj);
			[obj.CQI, obj.SINRS] = lteCQISelect(enb, enbObj.Tx.PDSCH, obj.EstChannelGrid, obj.NoiseEst);
			if isnan(obj.CQI)
				monsterLog('CQI is NaN - something went wrong in the selection.','ERR')
			end
    end
    
    function obj = computeOffset(obj, enbObj)
      % Compute offset based on PSS and SSS. Done every 0 and 5th subframe.
      if enbObj.NSubframe == 0 || enbObj.NSubframe == 5
        pssCorr = finddelay(enbObj.Tx.Ref.PSSWaveform,obj.Waveform);
        sssCorr = finddelay(enbObj.Tx.Ref.SSSWaveform,obj.Waveform);
        offset_ = min(pssCorr,sssCorr);
        obj.Offset = offset_;
      end
    end
		
		% reference measurements
		function obj  = referenceMeasurements(obj,enbObj)
            
			enb = struct(enbObj);
			%       RSSI is the average power of OFDM symbols containing the reference
			%       signals
			%       RxPw is the wideband power, e.g. the received power for the whole
			%       subframe, the RSSI must be the ratio of OFDM symbols occupying the
			%       subframe scaled with the wideband received power.
			%
			%		Note:
			% 		Since the OFDM demodulator/reference is assuming power is in dBm, 
			%       the factor of 30 dB which is used when converting to dBm needs to be removed, thus the -30
			Subframe = lteOFDMDemodulate(enb, setPower(obj.Waveform,obj.RxPwdBm-30)); %Apply recieved power to waveform.
			meas = hRSMeasurements(enb,Subframe);
			obj.RSRPdBm = meas.RSRPdBm;
			obj.RSSIdBm = meas.RSSIdBm;
			obj.RSRQdB = meas.RSRQdB;
		end
		
		function obj = applyOffset(obj, enbObj)
			if obj.PerfectSynchronization && ~isempty(obj.PathGains)
				obj.Offset = nrPerfectTimingEstimate(obj.PathGains,obj.PathFilters);
			else
				obj.computeOffset(enbObj)
			end
			obj.Waveform = obj.Waveform(obj.Offset+1:end);
		end
		
		% Block reception
		function obj  = logBlockReception(obj,ueObj)
			if ~isempty(ueObj.TransportBlock)
				% increase counters for BLER
				if obj.Crc == 0
					obj.Blocks.ok = 1;
				else
					obj.Blocks.err = 1;
				end
				obj.Blocks.tot = 1;
				
				%TB comparison and bit stats logging
				% extract the original TB and cast it to uint
				tbTx(1:ueObj.TransportBlockInfo.tbSize, 1) = ...
					ueObj.TransportBlock(1:ueObj.TransportBlockInfo.tbSize, 1);
				tbRx = obj.TransportBlock;
				
				% Check sizes and log a warning if they don't match
				sizeCheck = length(tbTx) - length(tbRx);
				if sizeCheck == 0
					% This is the normal case where we XOR the whole TBs and no extra error
					% bits are found
					[diff, ratio] = biterr(tbRx, tbTx);
					errEx = 0;
					tot = length(tbTx);
				else
					monsterLog('(ueReceiverModule - logBlockReception) TBs sizes mismatch', 'WRN');
					% In this case, we do the xor between the minimum common set of bits
					if sizeCheck > 0
						% the original TB was bigger than the received one, so test on the
						% usable portion and log the rest as errors
						sizeTest = length(tbTx) - sizeCheck;
						tbTest(1:sizeTest,1) = tbTx(1:sizeTest,1);
						[diff, ratio] = biterr(tbTest, tbRx);
						errEx = sizeCheck;
						tot = sizeTest;
					else
						% the original TB was smaller than the received one, so test on the
						% usable portion and discard the rest
						% convert the difference to absolute value
						sizeCheck = abs(sizeCheck);
						sizeTest = length(tbRx) - sizeCheck;
						tbTest(1:sizeTest,1) = tbRx(1:sizeTest,1);
						[diff, ratio] = biterr(tbTx, tbTest);
						errEx = 0;
						tot = sizeTest;
					end
				end
				
				obj.Bits.tot = tot;
				obj.Bits.err = diff + errEx;
				obj.Bits.ok = tot - diff;
			end
		end
			
		% This is used when a UE has not been scheduled in a specific round for the metrics recorded
		function obj = logNotScheduled(obj)
			obj.Blocks = struct('tot',0,'err',0,'ok',0);
      obj.Bits = struct('tot',0,'err',0,'ok',0);
		end

		% This is used when a UE received waveform cannot be demodulated
		function obj = logNotDemodulated(obj)
			obj.PostEvm = NaN;
      obj.PreEvm = NaN;
      obj.CQI = NaN;
      obj.Blocks = struct('tot',1,'err',1,'ok',0);
      obj.Bits = struct('tot',1,'err',1,'ok',0);
		end
		
		function plotSpectrum(obj)
			% TODO: Missing axis
			figure
			plot(10*log10(abs(fftshift(fft(obj.Waveform)))))
		end
		
		% Reset receiver
		function obj = reset(obj)
			obj.NoiseEst = [];
			obj.RSSIdBm = [];
			obj.RSRQdB = [];
			obj.RSRPdBm = [];
			obj.SINR = [];
			obj.SINRdB = [];
			obj.SNR = [];
			obj.SNRdB = [];
			obj.Waveform = [];
			obj.RxPwdBm = [];
			obj.Subframe = [];
			obj.EstChannelGrid = [];
			obj.EqSubframe = [];
			obj.TransportBlock = [];
			obj.Crc = [];
			obj.PreEvm = 0;
			obj.PostEvm = 0;
			obj.BLER = 0;
			obj.Throughput = 0;
			obj.SchIndexes = [];
			obj.PDSCH = [];
			obj.Blocks = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Bits = struct('ok', 0, 'err', 0, 'tot', 0);
		end
		
	end
	
	
	
end
