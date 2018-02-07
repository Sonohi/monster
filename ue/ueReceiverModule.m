classdef ueReceiverModule
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
		RxPwdBm; % Wideband
		IntSigLoss;
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
		Symbols;
		PDSCH;
		PropDelay;
		HistoryStats;
	end
	
	methods
		
		function obj = ueReceiverModule(Param, ueObj)
			obj.NoiseFigure = Param.ueNoiseFigure;
			obj.CQI = 3;
			obj.Blocks = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Bits = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Symbols = struct('ok', 0, 'err', 0, 'tot', 0);
			for iStation = 1:(Param.numMacro + Param.numMicro)
				cellstring = char(strcat("NCellID",int2str(iStation)));
				obj.HistoryStats.(cellstring) = struct('SINRdB',[],'SNRdB',[],'RxPwdBm',[]);
			end
		end
		
		function old_values = getFromHistory(obj, field, stationID)
			stationfield = strcat('NCellID',int2str(stationID));
			path = {'HistoryStats', stationfield, field};
			old_values = getfield(obj, path{:});
		end
		
		function obj = addToHistory(obj, field, stationID)
			
			old_values = obj.getFromHistory(field, stationID);
			stationfield = strcat('NCellID',int2str(stationID));
			path = {'HistoryStats', stationfield, field};
			new_value = getfield(obj, field);
			new_array = [old_values, new_value];
			obj = setfield(obj, path{:}, new_array);
			
		end
		
		function obj = set.Waveform(obj,Sig)
			obj.Waveform = Sig;
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
		
		function obj = set.RxPwdBm(obj,RxPwdBm)
			obj.RxPwdBm = RxPwdBm;
		end
		
		function obj = set.Offset(obj,offset)
			obj.Offset = offset;
		end
		
		function obj = set.PropDelay(obj,distance)
			obj.PropDelay = distance/physconst('LightSpeed');
		end
		
		function obj = set.Blocks(obj, blocks)
			obj.Blocks = blocks;
		end
		
		function obj = set.Bits(obj, bits)
			obj.Bits = bits;
		end
		
		function [returnCode, obj] = demodulateWaveform(obj,enbObj)
			% TODO: validate that a waveform exist.
			enb = cast2Struct(enbObj);
			Subframe = lteOFDMDemodulate(enb, obj.Waveform); %#ok
			
			if all(Subframe(:) == 0) %#ok
				returnCode = 0;
			else
				obj.Subframe = Subframe; %#ok
				returnCode = 1;
			end
			
		end
		
		% estimate channel at the receiver
		function obj = estimateChannel(obj, enbObj, cec)
			validateRxEstimateChannel(obj);
			rx = cast2Struct(obj);
			enb = cast2Struct(enbObj);
			[obj.EstChannelGrid, obj.NoiseEst] = lteDLChannelEstimate(enb, cec, rx.Subframe);
		end
		
		% equalize at the receiver
		function obj = equaliseSubframe(obj)
			validateRxEqualise(obj);
			obj.EqSubframe = lteEqualizeMMSE(obj.Subframe, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		function obj = estimatePdsch(obj, ue, enbObj)
			validateRxEstimatePdsch(obj);
			% first get the PRBs that where used for the UE with this receiver
			enb = cast2Struct(enbObj);
			
			obj.SchIndexes = find([enb.ScheduleDL.UeId] == ue.NCellID);
			
			% Store the full PRB set for extraction
			fullPrbSet = enb.Tx.PDSCH.PRBSet;
			
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
						prbIndices = find([enb.ScheduleDL.UeId] == uniqueIds(iUser));
						if prbIndices(1) < obj.SchIndexes(1)
							[~, mod, ~] = lteMCS(enb.ScheduleDL(prbIndices(1)).Mcs);
							enb.Tx.PDSCH.Modulation = mod;
							enb.Tx.PDSCH.PRBSet = (prbIndices - 1).';
							uePdschIndices = ltePDSCHIndices(enb, enb.Tx.PDSCH, enb.Tx.PDSCH.PRBSet);
							offset = offset + length(uePdschIndices);
						end
					end
				end
			end
			
			% Set the parameters of the PDSCH to those of the current UE
			[~, mod, ~] = lteMCS(enb.ScheduleDL(obj.SchIndexes(1)).Mcs);
			enb.Tx.PDSCH.Modulation = mod;
			enb.Tx.PDSCH.PRBSet = (obj.SchIndexes - 1).';
			
			% Now get all the PDSCH indexes and symbols out of the received grid
			% TODO for some reasons the built-in functions only work properly with the whole PDSCH
			fullPdschIndices = ltePDSCHIndices(enb, enb.Tx.PDSCH, fullPrbSet);
			[fullPdschRx, ~] = lteExtractResources(fullPdschIndices, obj.EqSubframe);
			
			% Filter out the PDSCH symbols and bits that are meant for this receiver.
			% The indices obtained with the function refer to positions in the main grid
			uePdschIndices = ue.SymbolsInfo.pdschIxs;
			uePdschRx = fullPdschRx(offset:offset + length(uePdschIndices) - 1);
			
			% Decode PDSCH
			[ueDlsch, uePdsch] = ltePDSCHDecode(enb, enb.Tx.PDSCH, uePdschRx);
			uePdsch = uePdsch{1};
			ueDlsch = ueDlsch{1};
			
			% The decoded DL-SCH bits are always returned as a cell array, so for 1 CW
			% cases convert it
			obj.PDSCH = uePdsch;
			% Decode DL-SCH
			[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, enb.Tx.PDSCH, ue.TransportBlockInfo.tbSize, ...
				ueDlsch);
		end
		
		% calculate the EVM
		function obj = calculateEvm(obj, enbObj)
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PreEvm = EVM(enbObj.Tx.ReGrid,obj.Subframe);
			s = sprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', obj.PreEvm);
			sonohilog(s,'NFO0')
			
			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PostEvm = EVM(enbObj.Tx.ReGrid,obj.EqSubframe);
			s = sprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', obj.PostEvm);
			sonohilog(s,'NFO0')
		end
		
		% select CQI
		function obj = selectCqi(obj, enbObj)
			enb = cast2Struct(enbObj);
			[obj.CQI, ~] = lteCQISelect(enb, enb.Tx.PDSCH, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		% reference measurements
		function obj  = referenceMeasurements(obj,enbObj)
            
			enb = cast2Struct(enbObj);
            
            %       RSSI is the average power of OFDM symbols containing the reference
			%       signals
			%       RxPw is the wideband power, e.g. the received power for the whole
			%       subframe, the RSSI must be the ratio of OFDM symbols occupying the
			%       subframe scaled with the wideband received power.
            Subframe = lteOFDMDemodulate(enb, setPower(obj.Waveform,obj.RxPwdBm-30)); %Apply recieved power to waveform.
            meas = hRSMeasurements(enb,Subframe);
            obj.RSRPdBm = meas.RSRPdBm;
            obj.RSSIdBm = meas.RSSIdBm;
            obj.RSRQdB = meas.RSRQdB;
           

		end
		
		% Block reception
		function obj  = logBlockReception(obj,ueObj)
			validateRxLogBlockReception(obj);
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
				sonohilog('(ReceiverModule logBlockReception) TBs sizes mismatch', 'WRN');
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
		
		% Symbols reception stats
		function obj = logSymbolsReception(obj, ue)
			symsTx(1:ue.SymbolsInfo.symSize, 1) = ue.Symbols(1:ue.SymbolsInfo.symSize,1);
			symsRx = obj.PDSCH;
			
			% Check sizes and log a warning if they don't match
			sizeCheck = length(symsTx) - length(symsRx);
			if sizeCheck == 0
				% Normal case
				[diff, ratio] = symerr(symsRx, symsTx);
				errEx = 0;
				tot = length(symsTx);
			else
				sonohilog('(ReceiverModule logSymbolsReception) Symbols sizes mismatch', 'WRN');
				% In this case, we do the xor between the minimum common set of bits
				if sizeCheck > 0
					% the original sym was bigger than the received one, so test on the
					% usable portion and log the rest as errors
					sizeTest = length(symsTx) - sizeCheck;
					symsTest(1:sizeTest,1) = symsTx(1:sizeTest,1);
					[diff, ratio] = symerr(symsTest, symsRx);
					errEx = sizeCheck;
					tot = sizeTest;
				else
					% the original sym was smaller than the received one, so test on the
					% usable portion and discard the rest
					% convert the difference to absolute value
					sizeCheck = abs(sizeCheck);
					sizeTest = length(symsRx) - sizeCheck;
					symsTest(1:sizeTest,1) = symsRx(1:sizeTest,1);
					[diff, ratio] = symerr(symsTx, symsTest);
					errEx = 0;
					tot = sizeTest;
				end
			end
			
			obj.Symbols.tot = tot;
			obj.Symbols.err = diff + errEx;
			obj.Symbols.ok = tot - diff;
		end
		
		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end
		
		% Reset receiver
		function obj = reset(obj)
			obj.NoiseEst = [];
			obj.RSSIdBm = 0;
			obj.RSRQdB = 0;
			obj.RSRPdBm = 0;
			obj.SINR = 0;
			obj.SINRdB = 0;
			obj.SNR = 0;
			obj.SNRdB = 0;
			obj.Waveform = 0;
			obj.RxPwdBm = 0;
			obj.IntSigLoss = 0;
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
		end
		
	end
	
	
	
end
