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
    RxPw; % Wideband
    IntSigLoss;
    RxSubFrame;
    EqSubFrame;
    TransportBlock;
    Crc;
  end

methods

  function obj = ReceiverModule(Param)
    obj.NoiseFigure = Param.ueNoiseFigure;
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

  function obj = set.RxPw(obj,RxPw)
    obj.RxPw = RxPw;
  end

  function [returnCode, obj] = demod(obj,enbObj)
    % TODO: validate that a waveform exist.
    enb = cast2Struct(enbObj);
    RxSubFrame = lteOFDMDemodulate(enb, obj.Waveform); %#ok

    if all(RxSubFrame(:) == 0) %#ok
      returnCode = 0;
    else
      obj.RxSubFrame = RxSubFrame; %#ok
      returnCode = 1;
    end


  end

	% estimate channel at the receiver
	function obj = estimateChannel(obj, enbObj, cec)
		validateRxEstimateChannel(obj);
		rx = cast2Struct(obj);
		enb = cast2Struct(enbObj);
		[obj.EstChannelGrid, obj.NoiseEst] = lteDLChannelEstimate(enb, cec, rx.RxSubFrame);
	end

	% equalize at the receiver
	function obj = equalise(obj)
		validateRxEqualise(obj);
		obj.EqSubFrame = lteEqualizeMMSE(obj.RxSubFrame, obj.EstChannelGrid, obj.NoiseEst);
	end

	function obj = estimatePdsch(obj, ue, enbObj)
		validateRxEstimatePdsch(obj);
		% first get the PRBs that where used for the UE with this receiver
		enb = cast2Struct(enbObj);
		allocIndexes = find([enb.Schedule.UeId] == ue.UeId);
		alloc = enb.Schedule(allocIndexes);

		% Now get the PDSCH symbols out of the whole grid for this receiver
		pdschIndices = ltePDSCHIndices(enb, enb.PDSCH, alloc);
		[pdschRx, pdschHest] = lteExtractResources(pdschIndices, enb.ReGrid, obj.NoiseEst);

		% Decode PDSCH
		dlschBits = ltePDSCHDecode(enb, enb.pdsch, pdschRx, pdschHest, obj.NoiseEst);
		% Decode DL-SCH
		[obj.TransportBlock, obj.Crc] = lteDLSCHDecode(enb, enb.pdsch, lenght(ue.TransportBlock), ...
		 	ue.Codeword);

	end

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
		obj.RxPw = 0;
		obj.IntSigLoss = 0;
		obj.RxSubFrame = [];
		obj.EqSubFrame = 0;
		obj.EstChannelGrid = [];
		obj.EqSubFrame = [];
		obj.TransportBlock = [];
		obj.Crc = [];
	end

  function obj  = referenceMeasurements(obj,enbObj)
    enb = cast2Struct(enbObj)
    rsmeas = hRSMeasurements(enb,obj.RxSubFrame)
    obj.RSSIdBm = rsmeas.RSSIdBm;
    obj.RSRPdBm = rsmeas.RSRPdBm;
    obj.RSRQdB = rsmeas.RSRQdB;
  end

end



end
