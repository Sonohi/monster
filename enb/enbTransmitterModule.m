classdef enbTransmitterModule
  properties
    Waveform;         %
    WaveformInfo;
    ReGrid;
    PDSCH;
    PBCH;
    Frame;
    FrameInfo;
    FrameGrid;
    TxPwdBm;
    NoiseFigure;
    NDLRB;
    Gain;
    PssRef;
    SssRef;
  end
  
  methods
    % Constructor
    function obj = enbTransmitterModule(enb, Param)
      obj.TxPwdBm = 10*log10(enb.Pmax)+30;
      obj.Gain = Param.eNBGain;
      obj.NoiseFigure = Param.eNBNoiseFigure;
			obj.NDLRB = enb.NDLRB;
			Nfft = 2^ceil(log2(12*enb.NDLRB/0.85));
			obj.Waveform = zeros(Nfft, 1);
			obj = setBCH(obj, enb);
			obj = resetResourceGrid(obj, enb);
			obj = initPDSCH(obj, enb.NDLRB);
			[obj.Frame, obj.FrameInfo, obj.FrameGrid] = generateDummyFrame(enb);
    end
    
    function EIRPSubcarrier = getEIRPSubcarrier(obj)
      % Returns EIRP per subcarrier in Watts
      EIRPSubcarrier = obj.getEIRP()/size(obj.ReGrid,1);
		end
		
    
    function EIRP = getEIRP(obj)
      % Returns EIRP in Watts
      EIRP = 10^((obj.getEIRPdBm())/10)/1000;
    end
    
    function EIRPdBm = getEIRPdBm(obj)
      EIRPdBm = obj.TxPwdBm + obj.Gain - obj.NoiseFigure;
    end
    
    % Setters
    % set Frame
    function obj = set.Frame(obj, frm)
      obj.Frame = frm;
    end
    
    % set FrameInfo
    function obj = set.FrameInfo(obj, info)
      obj.FrameInfo = info;
    end
    
    % set FrameGrid
    function obj = set.FrameGrid(obj, grid)
      obj.FrameGrid = grid;
    end
    
    % set Waveform
    function obj = set.Waveform(obj, wfm)
      obj.Waveform = wfm;
    end
    
    % set WaveformInfo
    function obj = set.WaveformInfo(obj, info)
      obj.WaveformInfo = info;
    end
    
    % set ReGrid
    function obj = set.ReGrid(obj, grid)
      obj.ReGrid = grid;
    end
    
    % Methods
    % set BCH
    function obj = setBCH(obj, enbObj)
      enb = cast2Struct(enbObj);
      mib = lteMIB(enb);
      bchCoded = lteBCH(enb, mib);
      obj.PBCH = struct('bch', bchCoded, 'unit', 1);
    end
    
    % Set default subframe resource grid
    function obj = resetResourceGrid(obj, enbObj)
      enb = cast2Struct(enbObj);
      tx = cast2Struct(obj);
      % Create empty grid
      regrid = lteDLResourceGrid(enb);
      
      % Reference signals
      indRs = lteCellRSIndices(enb, 0);
      rs = lteCellRS(enb, 0);
      
      % Synchronization signals
      indPss = ltePSSIndices(enb);
      pss = ltePSS(enb);
      indSss = lteSSSIndices(enb);
      sss = lteSSS(enb);
      
      % Compute reference waveform of synchronization signals, used to compute offset
      obj = obj.computeReferenceWaveform(pss, indPss, sss, indSss, enb);
      
      % Channel format indicator
      cfi = lteCFI(enb);
      indPcfich = ltePCFICHIndices(enb);
      pcfich = ltePCFICH(enb, cfi);
      
      % % put signals into the grid
      regrid(indRs) = rs;
      regrid(indPss) = pss;
      regrid(indSss) = sss;
      regrid(indPcfich) = pcfich;
      
      % every 10 ms we need to broadcast a unit of the BCH
      if (mod(enb.NSubframe, 10) == 0 && tx.PBCH.unit <= 4)
        fullPbch = ltePBCH(enb,tx.PBCH.bch);
        indPbch = ltePBCHIndices(enb);
        
        % find which portion of the PBCH we need to send in this frame and insert
        a = (tx.PBCH.unit - 1) * length(indPbch) + 1;
        b = tx.PBCH.unit * length(indPbch);
        pbch = fullPbch(a:b, 1);
        regrid(indPbch) = pbch;
        
        % finally update the unit counter
        tx.PBCH.unit = tx.PBCH.unit + 1;
      end
      
      % Write back into the objects
      obj.PBCH = tx.PBCH;
      obj.ReGrid = regrid;
    end
    
    % cast object to struct
    function txStruct = cast2Struct(obj)
      txStruct = struct(obj);
    end
    
    % Reset transmitter
    function obj = reset(obj, enbObj, nextSchRound)
      % every 40 ms the cell has to broadcast its identity with the BCH
      % check if we need to regenerate that
      if mod(nextSchRound, 40) == 0
        obj = obj.setBCH(enbObj);
      end
      
      % Reset the grid and put in the grid RS, PSS and SSS
      obj = obj.resetResourceGrid(enbObj);
      
      % Reset the waveform and the grid transmitted
      obj.Waveform = [];
      obj.WaveformInfo = [];
    end
    
    % modulate TX waveform
    function obj = modulateTxWaveform(obj, enbObj)
      enb = cast2Struct(enbObj);
      tx = cast2Struct(obj);
      % Add PDCCH and generate a random codeword to emulate the control info carried
      pdcchParam = ltePDCCHInfo(enb);
      ctrl = randi([0,1],pdcchParam.MTot,1);
      [pdcchSym, pdcchInfo] = ltePDCCH(enb,ctrl);
      indPdcch = ltePDCCHIndices(enb);
      tx.ReGrid(indPdcch) = pdcchSym;
      % Assume lossless transmitter
      [obj.Waveform, obj.WaveformInfo] = lteOFDMModulate(enb, tx.ReGrid);
      % set in the WaveformInfo the percentage of OFDM symbols used for this subframe
      % for power scaling
      used = length(find(abs(tx.ReGrid) ~= 0));
      obj.WaveformInfo.OfdmEnergyScale = used/numel(tx.ReGrid);
    end
    
    function obj = computeReferenceWaveform(obj, pss, indPss, sss, indSss, enb)
      % Compute and store reference waveforms of PSS and SSS, generated every 0th and 5th subframe
      if enb.NSubframe == 0 || enb.NSubframe == 5
        pssGrid=lteDLResourceGrid(enb); % Empty grid for just the PSS symbols
        pssGrid(indPss)=pss;
        obj.PssRef = lteOFDMModulate(enb,pssGrid);
        sssGrid=lteDLResourceGrid(enb); % Empty grid for just the PSS symbols
        sssGrid(indSss)=sss;
        obj.SssRef = lteOFDMModulate(enb,sssGrid);
      end
    end
    
    % insert PDSCH symbols in grid at correct indexes
    function obj = setPDSCHGrid(obj, enb, syms)
      regrid = obj.ReGrid;
      
      % get PDSCH indexes
      [indPdsch, pdschInfo] = ltePDSCHIndices(enb, obj.PDSCH, obj.PDSCH.PRBSet);
      
      % pad for unused subcarriers
      padding(1:length(indPdsch) - length(syms), 1) = 0;
      syms = cat(1, syms, padding);
      
      % insert symbols into grid
      regrid(indPdsch) = syms;
      
      % Set back in object
      obj.ReGrid = regrid;
      
    end
  end
  
  methods (Access = private)
    % initialise PDSCH
    %
    % TM1 is used (1 antenna) thus Rho is 0 dB, if MIMO change to 3 dB
    % See 36.213 5.2
    function obj = initPDSCH(obj, NDLRB)
      ch = struct(...
        'TxScheme', 'Port0',...
        'Modulation', {'QPSK'},...
        'NLayers', 1, ...
        'Rho', 0,...
        'RNTI', 1,...
        'RVSeq', [0 1 2 3],...
        'RV', 0,...
        'NHARQProcesses', 8, ...
        'NTurboDecIts', 5,...
        'PRBSet', (0:NDLRB-1)',...
        'TrBlkSizes', [], ...
        'CodedTrBlkSizes', [],...
        'CSIMode', 'PUCCH 1-0',...
        'PMIMode', 'Wideband',...
        'CSI', 'On');
      obj.PDSCH = ch;
    end
  end
end
