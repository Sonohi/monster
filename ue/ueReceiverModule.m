classdef ueReceiverModule < matlab.mixin.Copyable
	properties
		ChannelConditions = struct();
		NoiseFigure;
		EstChannelGrid;
		NoiseEst;
		RSSIdBm;
		RSRQdB;
		RSRPdBm;
		Waveform; % Manipulated waveform after offset is applied
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
		SINRdB;
		Demod;
		AntennaArray;
		ueObj; % Parent UE handle
		AntennaGain;
	end

	properties (Access = private)
		PerfectSynchronization;
		FadingActive;
	end
	
	methods
		
		function obj = ueReceiverModule(ueObj, Config)
			obj.Offset = 0;
			obj.ueObj = ueObj;
			obj.NoiseFigure = Config.Ue.noiseFigure;
			% TODO check sub band reporting size
			obj.CQI = struct('wideBand', 3, 'subBand', 3*ones(9,1));
			obj.SINRdB = struct('wideBand', [], 'subBand', []);
			obj.Blocks = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Bits = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.PerfectSynchronization = Config.Channel.perfectSynchronization;
			obj.FadingActive = Config.Channel.fadingActive;
			obj.AntennaGain = Config.Ue.antennaGain;
			MimoConfig = generateMimoConfig(Config);
			if strcmp(Config.Ue.antennaType, 'vivaldi')
				obj.AntennaArray = AntennaArray(Config.Ue.antennaType, obj.ueObj.Logger, Config.Phy.downlinkFrequency*10e5);
			else
				obj.AntennaArray = AntennaArray(Config.Ue.antennaType, obj.ueObj.Logger, MimoConfig);	
			end
		end
		
		function obj = setSNR(obj, SNR)
			obj.ChannelConditions.SNR = SNR;
			obj.ChannelConditions.SNRdB = 10*log10(SNR);
		end
		
		function obj = setSINR(obj, SINR)
			obj.ChannelConditions.SINR = SINR;
			obj.ChannelConditions.SINRdB = 10*log10(SINR);
		end
		
		function obj = setRxPw(obj, RxPw)
			obj.ChannelConditions.RxPw = RxPw; % Watt
			obj.ChannelConditions.RxPwdBm = 10*log10(RxPw)+30;
		end
		
		function obj = setPathConditions(obj, PathGains, PathFilters)
			% Used for perfect synchronization
			obj.ChannelConditions.PathGains = PathGains;
			obj.ChannelConditions.PathFilters = PathFilters;
		end
		
		function obj = setWaveform(obj, Waveform, WaveformInfo)
			obj.Waveform = Waveform;
			obj.ChannelConditions.WaveformInfo = WaveformInfo;
		end
			
		function loss = getLoss(obj, TxPosition, RxPosition)
			% Get loss of receiver module by combining noise figure with gain from antenna element
			% In the case of an ideal omni directional (isotropic) antenna the loss is equal to the noise figure
			AntennaGain = obj.AntennaArray.getAntennaGains(TxPosition, RxPosition);
			loss = -obj.NoiseFigure + AntennaGain{1}  + obj.AntennaGain;
		end

		function oldValues = getFromHistory(obj, field, cellId)
			cellField = strcat('NCellID',int2str(cellId));
			path = {'HistoryStats', cellField, field};
			oldValues = getfield(obj, path{:});
		end
		
		function obj = addToHistory(obj, field, cellId)
			oldValues = obj.getFromHistory(field, cellId);
			cellField = strcat('NCellID',int2str(cellId));
			path = {'HistoryStats', cellField, field};
			newValue = getfield(obj, field);
			newArray = [oldValues, newValue];
			obj = setfield(obj, path{:}, newArray);		
		end

			
		function obj = set.PropDelay(obj,distance)
			obj.PropDelay = distance/physconst('LightSpeed');
		end

		function obj = receiveDownlink(obj, enb, cec)
			% Apply the receiver chain for subframe recovery
			
			% Find synchronization, apply offset
			if obj.FadingActive
				obj.applyOffset(enb);
			end
			
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
				obj.estimatePdsch(enb);

				% Calculate EVM
				obj.calculateEvm(enb);

				% Log block reception
				obj.logBlockReception();
			else
				obj.ueObj.Logger.log(sprintf('(UE RECEIVER MODULE - downlinkReception) not able to demodulate Cell(%i) -> User(%i)...',enb.NCellID, obj.NCellID),'WRN');
				obj.logNotDemodulated();
				obj.CQI = struct('wideBand', 3, 'subBand', 3*ones(9,1));

			end
			% TODO: Select PMI, RI
		end
		
		function demodulateWaveform(obj,enbObj)
			% demodulateWaveform demodulates waveform and store extracted subframe.
			% 
			% :param obj: ueReceiverModule instance
			% :param enbObj: EvolvedNodeB instance
			% :sets obj.Subframe, obj.Demod:
			%

			if isempty(obj.Waveform)
				obj.ueObj.Logger.log('(UE RECEIVER MODULE - demodulateWaveform) No waveform detected.', 'ERR', 'MonsterUeReceiverModule:EmptyWaveform')
			end

			enb = struct(enbObj);
			Subframe = lteOFDMDemodulate(enb, obj.Waveform); %#ok
			
			if all(Subframe(:) == 0) %#ok
				obj.Demod = 0;
			else
				obj.Subframe = Subframe; %#ok
				obj.Demod = 1;
			end
		end

		function validateSubframe(obj)
			% validateSubframe is a validator for the subframe
			% 
			% :param obj: ueReceiverModule instance
			% 
			if isempty(obj.Subframe)
				obj.ueObj.Logger.log('Empty subframe in receiver module. Did it demodulate?','ERR','MonsterUeReceiverModule:EmptySubframe')
			end	
		end
		
		function obj = estimateChannel(obj, enbObj, cec)
			% Estimate the channel matrix using a channel estimator and the enb structure
			%
			% Sets obj.EstChannelGrid (H matrix) and obj.NoiseEst (Noise power variance).
			enb = struct(enbObj);
			obj.validateSubframe();
			[obj.EstChannelGrid, obj.NoiseEst] = lteDLChannelEstimate(enb, cec, obj.Subframe);
		end
		
		
		function obj = equaliseSubframe(obj)
			% equaliseSubframe implements MMSE equalizer of subframe using channel estimation
			%
			% Uses obj.Subframe, obj.EstChannelGrid and obj.NoiseEst
			% Sets obj.EqSubframe
			obj.validateSubframe()
			if isempty(obj.EstChannelGrid) || isempty(obj.NoiseEst)
				obj.ueObj.Logger.log('Empty channel estimation and noise estimation.','ERR', 'MonsterUeReceiverModule:EmptyChannelEstimation')
			end

			obj.EqSubframe = lteEqualizeMMSE(obj.Subframe, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		function obj = estimatePdsch(obj, enbObjHandle)
			% estimatePdsch extracts the received PDSCH symbols for this UE from the received subframe and decodes them
			% 
			% :param obj: ueReceiverModule instance
			% :param enbObjHandle: EvolvedNodeB instance that the UE is associated to 
			% :returns obj: ueReceiverModule updated instance

			% Check that this UE had symbols created in this round
			if ~isempty(obj.ueObj.SymbolsInfo)
				uePrbSet = obj.ueObj.SymbolsInfo.PRBSet;
				if ~isempty(uePrbSet)
					% Cast the eNodeB object handle to struct for local usage
					enb = struct(enbObjHandle);
					
					% Extract the PDSCH indices that this UE had allocated 
					uePdschIndices = obj.ueObj.SymbolsInfo.pdschIxs;
					% Extract the corresponding received PDSCH symbols from the equalised subframe
					[uePdschRx, uePdschRxInfo] = lteExtractResources(uePdschIndices, obj.EqSubframe);

					% Edit a local copy of the PDSCH configuration structure to decode the received symbols
					pdschConfig = enbObjHandle.Tx.PDSCH;
					mod = enbObjHandle.getModulationDL(obj.ueObj);
					pdschConfig.Modulation = mod;
					pdschConfig.PRBSet = uePrbSet;

					% Decode the PDSCH symbols received for this UE
					% The variables returned are cell arrays, so for the current 1 CW case select the first one
					[ueDlsch, uePdsch] = ltePDSCHDecode(enb, pdschConfig, uePdschRx);
					uePdsch = uePdsch{1};
					ueDlsch = ueDlsch{1};

					% Save the decoded PDSCH for this UE and decode also its DL-SCH 
					obj.PDSCH = uePdsch;
					[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, pdschConfig, obj.ueObj.TransportBlockInfo.tbSize, ueDlsch);
				end
			end
		end
		
		% calculate the EVM
		function obj = calculateEvm(obj, enbObj)
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PreEvm = EVM(enbObj.Tx.ReGrid,obj.Subframe);
			s = sprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', obj.PreEvm);
			obj.ueObj.Logger.log(s,'NFO0');
			
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PostEvm = EVM(enbObj.Tx.ReGrid,obj.EqSubframe);
			s = sprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', obj.PostEvm);
			obj.ueObj.Logger.log(s,'NFO0');
		end
		
		% select CQI
		function obj = selectCqi(obj, enbObj)
			enb = struct(enbObj);
			% Depending on the PDSCH CSI mode parameter, the CQI and SINRS reported vary. 
			[cqiValues, sinrValues] = lteCQISelect(enb, enbObj.Tx.PDSCH, obj.EstChannelGrid, obj.NoiseEst);
			switch enbObj.Tx.PDSCH.CSIMode
				case 'PUCCH 1-0' 
					% In this case, only a single wideband value is returned for both CQI and SINR
					obj.CQI.wideBand = cqiValues;
					obj.CQI.subBand(1:length(obj.CQI.subBand)) = cqiValues;
					obj.SINRdB.wideBand = sinrValues;
					obj.SINRdB.subBand(1: length(obj.SINRdB.subBand)) = sinrValues;
				case 'PUSCH 3-0'
					% In this case, the returned values are in an array.
					% The first element holds the wideband value.
					% following elements are differential values from the wideband one for each sub band
					obj.CQI.wideBand = cqiValues(1);
					obj.SINRdB.wideBand = sinrValues(1);
					for iValue = 2:length(cqiValues)
						obj.CQI.subBand(iValue - 1) = obj.CQI.wideBand + cqiValues(iValue);
						obj.SINRdB.subBand(iValue - 1) = sinrValues(iValue);
					end
				otherwise
					obj.ueObj.Logger.log('(UE RECEIVER - selectCqi) selected PDSCH CSImode is not yet supported', 'ERR');
				end
			if isnan(obj.CQI.wideBand)
				obj.ueObj.Logger.log('(UE RECEIVER - selectCqi) something went wrong, widbeand CQI is invalid','ERR');
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
			Subframe = lteOFDMDemodulate(enb, setPower(obj.Waveform,obj.ChannelConditions.RxPwdBm-30)); %Apply recieved power to waveform.
			meas = refMeasurements(enb,Subframe);
			obj.RSRPdBm = meas.RSRPdBm;
			obj.RSSIdBm = meas.RSSIdBm;
			obj.RSRQdB = meas.RSRQdB;
		end
		
		function obj = applyOffset(obj, enbObj)
			% Applies and computes offset to the waveform property. Can use two different ways of offset calculation
			% 1. Perfect timing estimate giving the NR toolbox and the pathgains/filters of the channel
			% 2. Offset computation using xcorr and PSS/SSS signals
			% 
			% Updates obj.Waveform
			PathGainsSet = false; % Stupid matlab
			if ~isempty(fieldnames(obj.ChannelConditions))
				if isfield(obj.ChannelConditions,'PathGains')
					if ~isempty(obj.ChannelConditions.PathGains)
						PathGainsSet = true;
					end
				end
			end
			
			if obj.PerfectSynchronization && PathGainsSet
				obj.Offset = nrPerfectTimingEstimate(obj.ChannelConditions.PathGains,obj.ChannelConditions.PathFilters);
			else
				obj.computeOffset(enbObj);
			end
			obj.Waveform = obj.Waveform(obj.Offset+1:end);
		end
		
		function obj  = logBlockReception(obj)
			% logBlockReception logs the reception status of the TB and its bits for stats recording
			% 
			% :param obj: ueReceiverModule instance
			% :sets
			%
			
			if ~isempty(obj.ueObj.TransportBlock)
				% increase counters for BLER
				if obj.Crc == 0
					obj.Blocks.ok = 1;
				else
					obj.Blocks.err = 1;
				end
				obj.Blocks.tot = 1;
				
				%TB comparison and bit stats logging
				% extract the original TB and cast it to uint
				tbTx(1:obj.ueObj.TransportBlockInfo.tbSize, 1) = ...
					obj.ueObj.TransportBlock(1:obj.ueObj.TransportBlockInfo.tbSize, 1);
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
					obj.ueObj.Logger.log('(UE RECEIVER MODULE - logBlockReception) TBs sizes mismatch', 'WRN');
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
				obj.Bits.ratio = ratio;
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
      obj.CQI = struct('wideBand', -1, 'subBand', -1*ones(9,1));
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
			obj.ChannelConditions = struct();
			obj.Waveform = [];
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
