classdef ReceiverModule
  properties
      NoiseFigure;
      RSSI;
      RSQI;
      RSRP;
      SINR;
      SINRdB;
      SNR;
      SNRdB;
      Waveform;
      RxPw; % Wideband
      intSigLoss;
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


end



end
