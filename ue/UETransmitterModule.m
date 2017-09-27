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
    ReGrid;
    pucchformat;
    NCellID;
  end
  
  methods
    
    function obj = UETransmitterModule(Param)
      
      obj.NULRB = 6;                   % 6 Resource Blocks
      obj.DuplexMode = 'FDD';          % Frequency Division Duplexing (FDD)
      obj.CyclicPrefixUL = 'Normal';   % Normal cyclic prefix length
      obj.NTxAnts = 1;                 % Number of transmission antennas
      obj.pucchformat = 1;
      obj.prach.Interval = Param.PRACHInterval;
      obj.prach.Format = 0;          % PRACH format: TS36.104, Table 8.4.2.1-1, CP length of 0.10 ms, typical cell range of 15km
      obj.prach.SeqIdx = 22;         % Logical sequence index: TS36.141, Table A.6-1
      obj.prach.CyclicShiftIdx = 1;  % Cyclic shift index: TS36.141, Table A.6-1
      obj.prach.HighSpeed = 0;       % Normal mode: TS36.104, Table 8.4.2.1-1
      obj.prach.FreqOffset = 0;      % Default frequency location
      obj.prach.PreambleIdx = 32;    % Preamble index: TS36.141, Table A.6-1
      obj.prachinfo = ltePRACHInfo(obj, obj.prach);
      
      
    end
    
    
    
    function obj = setPRACH(obj)
      obj.prach.TimingOffset = obj.prachinfo.BaseOffset + obj.NSubframe/10.0;
      obj.Waveform = ltePRACH(obj, obj.prach);
    end

    function obj = mapGridAndModulate(obj, CellID, NSubframe, NFrame)

      obj.NSubframe = NSubframe;
      obj.NFrame = NFrame;
      obj.NCellID = CellID;
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
  
        chs.ResourceIdx = 0;
        switch obj.pucchformat
          case 1
            % TODO Add HARQ indicator value
            pucchsym = ltePUCCH1(obj,chs,[]);
            pucchind = ltePUCCH1Indices(obj,chs);
            drsSeq = ltePUCCH1DRS(obj,chs);
            drsSeqind = ltePUCCH1DRSIndices(obj,chs);
            
          case 2
            % TODO Add coded CQI/PMI bits to PUCCH
            % TODO Add HARQ bits
            pucchsym = ltePUCCH2(obj,chs,[]);
            pucchind = ltePUCCH2Indices(obj,chs);
            drsSeq = ltePUCCH2DRS(obj,chs);
            drsSeqind = ltePUCCH2DRSIndices(obj,chs);
            
          case 3
            % TODO Add HARQ bits
            pucchsym = ltePUCCH3(obj,chs,[])
            pucchind = ltePUCCH3Indices(obj,chs);
            drsSeq = ltePUCCH3DRS(obj,chs);
            drsSeqind = ltePUCCH3DRSIndices(obj,chs);
        end
        
        % Configure PUSCH 
        
        % Configure SRS
        
        % Modulate SCFDMA
        
        % filler symbols
        obj.reGrid = reshape(lteSymbolModulate(randi([0,1],prod(dims)*2,1), ...
          'QPSK'),dims);
        
        obj.Waveform = lteSCFDMAModulate(obj,obj.reGrid);
        
      end
    end
  end
  
end
