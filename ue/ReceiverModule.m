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
	end

	methods

		function obj = ReceiverModule(Param)
			obj.NoiseFigure = Param.ueNoiseFigure;
			obj.WCQI = 3;
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
			allocIndexes = find([enb.Schedule.UeId] == ue.UeId);
			allocIndexes = allocIndexes';

			% Now get the PDSCH symbols out of the whole grid for this receiver
			pdschIndices = ltePDSCHIndices(enb, enb.PDSCH, allocIndexes);
			[pdschRx, ~] = lteExtractResources(pdschIndices, enb.ReGrid);

			% Decode PDSCH
			dlschBits = ltePDSCHDecode(enb, enb.PDSCH, pdschRx);
			% Decode DL-SCH
			[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, enb.PDSCH, ue.TransportBlockInfo.tbSize, ...
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
			obj.PreEvm = EVM(enbObj.ReGrid,obj.Subframe);
			s = sprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', obj.PreEvm);
			sonohilog(s,'NFO0')

			EVM = comm.EVM;
			EVM.AveragingDimensions = [1 2];
			obj.PostEvm = EVM(enbObj.ReGrid,obj.EqSubframe);
			s = sprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', obj.PostEvm);
			sonohilog(s,'NFO0')
		end

		% select CQI
		function obj = selectCqi(obj, enbObj)
			enb = cast2Struct(enbObj);
			[obj.WCQI, obj.SINR] = lteCQISelect(enb, enb.PDSCH, obj.EstChannelGrid, obj.NoiseEst);
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
			BLER = 0;
			Throughput = 0;
		end

	end



end
