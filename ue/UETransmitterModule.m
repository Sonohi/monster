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
      
      obj.prach.Interval = Param.PRACHInterval;
      obj.prach.Format = 0;          % PRACH format: TS36.104, Table 8.4.2.1-1, CP length of 0.10 ms, typical cell range of 15km
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
      % Check if upllink needs to consist of PRACH
      % TODO: changes to sequence and preambleidx given unique user ids
      if mod(obj.NSubframe,obj.prach.Interval) == 0
    
         obj = obj.setPRACH;
        
      else
        % Get size of resource grid and map channels.
        dims = lteULResourceGridSize(obj);
         
        % Decide on format of PUCCH (1, 2 or 3)
        % Format 1 is Scheduling request with/without bits for HARQ
        % Format 2 is CQI with/without bits for HARQ
        % Format 3 Bits for HARQ
        
        % Configure PUSCH with/without DRS
        
        % Configure SRS
        
        % Modulate SCFDMA
        
        % filler symbols
        reGrid = reshape(lteSymbolModulate(randi([0,1],prod(dims)*2,1), ...
          'QPSK'),dims);
        
        obj.Waveform = lteSCFDMAModulate(obj,reGrid);
        
      end

    end
    
    function obj = setPRACH(obj)
      obj.prach.TimingOffset = obj.prachinfo.BaseOffset + obj.NSubframe/10.0;
      obj.Waveform = ltePRACH(obj, obj.prach);
    end
  end
  
end
