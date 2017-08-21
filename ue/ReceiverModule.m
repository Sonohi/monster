classdef ReceiverModule
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
		WCQI;
		Offset;
		BLER;
		Throughput;
		SchIndexes;
		Blocks;
		Bits;
	end
	
	methods
		
		function obj = ReceiverModule(Param)
			obj.NoiseFigure = Param.ueNoiseFigure;
			obj.WCQI = 3;
			obj.Blocks = struct('ok', 0, 'err', 0, 'tot', 0);
			obj.Bits = struct('ok', 0, 'err', 0, 'tot', 0);
		end
		
		function obj = set.Waveform(obj,Sig)
			obj.Waveform = Sig;
		end
		
		function obj = set.SINR(obj,SINR)
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
		
		function [returnCode, obj] = demod(obj,enbObj)
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
		function obj = equalise(obj)
			validateRxEqualise(obj);
			obj.EqSubframe = lteEqualizeMMSE(obj.Subframe, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		function obj = estimatePdsch(obj, ue, enbObj)
			validateRxEstimatePdsch(obj);
			% first get the PRBs that where used for the UE with this receiver
			enb = cast2Struct(enbObj);
			obj.SchIndexes = find([enb.Schedule.UeId] == ue.UeId);
			obj.SchIndexes = obj.SchIndexes';
			
			% Now get the PDSCH symbols out of the whole grid for this receiver
			pdschIndices = ltePDSCHIndices(enb, enb.Tx.PDSCH, obj.SchIndexes);
			[pdschRx, ~] = lteExtractResources(pdschIndices, enb.Tx.ReGrid);
			
			% Decode PDSCH
			dlschBits = ltePDSCHDecode(enb, enb.Tx.PDSCH, pdschRx);
			% Decode DL-SCH
			[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, enb.Tx.PDSCH, ue.TransportBlockInfo.tbSize, ...
				dlschBits);
			% lteDLSCHDecode returns a cell array for the estimated TB, convert
			% that to a matrix
			if iscell(obj.TransportBlock)
				obj.TransportBlock = obj.TransportBlock{1};
			end
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
			[obj.WCQI, obj.SINR] = lteCQISelect(enb, enb.Tx.PDSCH, obj.EstChannelGrid, obj.NoiseEst);
		end
		
		% reference measurements
		function obj  = referenceMeasurements(obj,enbObj)
			enb = cast2Struct(enbObj);
			
			%       rxSig = setPower(obj.Waveform,obj.RxPwdBm);
			%rxSig = obj.Waveform*sqrt(10^((obj.RxPwdBm-30)/10));
			%    Subframe = lteOFDMDemodulate(enb, rxSig); %#ok
			%  rsmeas = hRSMeasurements(enb, Subframe);
			
			%       RSSI is the average power of OFDM symbols containing the reference
			%       signals
			%       RxPw is the wideband power, e.g. the received power for the whole
			%       subframe, the RSSI must be the ratio of OFDM symbols occupying the
			%       subframe scaled with the wideband received power.
			%       TODO: Replace this approximation with correct calculation on
			%       demodulated grid.
			RSSI = 0.92*10^((obj.RxPwdBm-30)/10); %mWatts
			obj.RSSIdBm = 10*log10(RSSI)+30;
		end
		
		% Block reception
		function obj  = logBlockReception(obj,ueObj)
			validateRxLogBlockReception(obj);
			% increase counters for BLER
			if obj.Crc
				obj.Blocks.ok = obj.Blocks.ok + 1;
			else
				obj.Blocks.err = obj.Blocks.err + 1;
			end
			obj.Blocks.tot = obj.Blocks.tot + 1;
			
			%TB comparison and bit stats logging
			% extract the original TB and cast it to uint
			tbOriginal(1:ueObj.TransportBlockInfo.tbSize, 1) = ...
				ueObj.TransportBlock(1:ueObj.TransportBlockInfo.tbSize, 1);
			tbOriginal = uint64(tbOriginal);
			tbReceived = uint64(obj.TransportBlock);
			
			
			% Check sizes and log a warning if they don't match
			sizeCheck = length(tbOriginal) - length(tbReceived);
			if sizeCheck == 0
				% This is the normal case where we XOR the whole TBs and no extra error
				% bits are found
				diff = bitxor(tbReceived, tbOriginal);
				errEx = 0;
				
			else
				sonohilog('(ReceiverModule logBlockReception) TBs sizes mismatch', 'WRN');
				% In this case, we do the xor between the minimum common set of bits
				if sizeCheck > 0
					% the original TB was bigger than the received one, so test on the
					% usable portion and log the rest as errors
					sizeTest = length(tbOriginal) - sizeCheck;
					tbTest(1:sizeTest) = tbOriginal(1:sizeTest);
					diff = bitxor(tbTest, tbReceived);
					errEx = sizeCheck;
				else
					% the original TB was smaller than the received one, so test on the
					% usable portion and discard the rest
					sizeTest = length(tbReceived) - sizeCheck;
					tbTest(1:sizeTest) = tbReceived(1:sizeTest);
					diff = bitxor(tbOriginal, tbTest);
					% TODO check the assumption of discarding the rest of the received TB
					errEx = 0;
				end
			end
			
			obj.Bits.tot = obj.Bits.tot + length(diff);
			obj.Bits.err = obj.Bits.err + sum(diff) + errEx;
			obj.Bits.ok = obj.Bits.ok + length(diff) - sum(diff) - errEx;
		end
		
		% Error bits
		function obj  = calculateThroughput(obj,enbObj)
			validateRxCalculateThroughput(obj);
			enb = cast2Struct(enbObj);
			%
		end
		
		% cast object to struct
		function objstruct = cast2Struct(obj)
			objstruct = struct(obj);
		end
		
		% Reset receiver
		function obj = resetReceiver(obj)
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
		end
		
	end
	
	
	
end
