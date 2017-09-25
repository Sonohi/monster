classdef UETransmitterModule
  properties
    NULRB;
    DuplexMode;
    CyclicPrefixUL
    NTxAnts;
    prach;
    prachinfo;
    Waveform;
    NSubframe;
    NFrame;
  end
  
  methods
    
    function obj = UETransmitterModule(Param)
      obj.NULRB = 6;                   % 6 Resource Blocks
      obj.DuplexMode = 'FDD';          % Frequency Division Duplexing (FDD)
      obj.CyclicPrefixUL = 'Normal';   % Normal cyclic prefix length
      obj.NTxAnts = 1;                 % Number of transmission antennas
      
      obj.prach.Format = 0;          % PRACH format: TS36.104, Table 8.4.2.1-1
      obj.prach.SeqIdx = 22;         % Logical sequence index: TS36.141, Table A.6-1
      obj.prach.CyclicShiftIdx = 1;  % Cyclic shift index: TS36.141, Table A.6-1
      obj.prach.HighSpeed = 0;       % Normal mode: TS36.104, Table 8.4.2.1-1
      obj.prach.FreqOffset = 0;      % Default frequency location
      obj.prach.PreambleIdx = 32;    % Preamble index: TS36.141, Table A.6-1
      obj.prachinfo = ltePRACHInfo(obj, obj.prach);
      
      
    end
    
    
    function obj = modulateTxWaveform(obj, NSubframe, NFrame)
      obj.NSubframe = NSubframe;
      obj.NFrame = NFrame;
      obj.prach.TimingOffset = obj.prachinfo.BaseOffset + obj.NSubframe/10.0;
      %% obj.Waveform = ltePRACH(obj, obj.prach);
      dims = lteULResourceGridSize(obj);
      reGrid = reshape(lteSymbolModulate(randi([0,1],prod(dims)*2,1), ...
          'QPSK'),dims);
      obj.Waveform = lteSCFDMAModulate(obj,reGrid);
    end
    
  end
  
end
