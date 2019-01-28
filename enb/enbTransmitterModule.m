classdef enbTransmitterModule < matlab.mixin.Copyable
  properties
    Waveform;
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
		Enb;
		Freq;
		Ref = struct('ReGrid',[], 'Waveform',[], 'WaveformInfo',[])
		AntennaArray;
		AntennaType; 
  end
  
  methods
		function obj = enbTransmitterModule(enb, Config)
			% enbTransmitterModule
			%
			% :param enb:
			% :param Config:
			% :returns obj:
			%

			obj.Enb = enb;
			obj.TxPwdBm = 10*log10(enb.Pmax)+30;
			switch enb.BsClass
				case 'macro'
					obj.Gain = Config.MacroEnb.antennaGain;
					obj.NoiseFigure = Config.MacroEnb.noiseFigure;
					obj.AntennaArray = AntennaArray(Config.MacroEnb.antennaType);
				case 'micro'
					obj.Gain = Config.MicroEnb.antennaGain;
					obj.NoiseFigure = Config.MicroEnb.noiseFigure;
					obj.AntennaArray = AntennaArray(Config.MicroEnb.antennaType);
				case 'pico'
					obj.Gain = Config.PicoEnb.antennaGain;
					obj.NoiseFigure = Config.PicoEnb.noiseFigure;
					obj.AntennaArray = AntennaArray(Config.PicoEnb.antennaType);
				otherwise
					monsterLog(sprintf('(ENODEB TRANSMITTER - constructor) eNodeB %i has an invalid base station class %s', enb.NCellID, enb.BsClass), 'ERR');
			end
			obj.NDLRB = enb.NDLRB;
			Nfft = 2^ceil(log2(12*enb.NDLRB/0.85));
			obj.Waveform = zeros(Nfft, 1);
			obj.setBCH();
			obj.resetResourceGrid();
			obj.initPDSCH();
			obj.Freq = Config.Phy.downlinkFrequency;
		end
		
		function obj = createReferenceSubframe(obj)
			enb = struct(obj.Enb);
			
			% Reference
			grid = lteResourceGrid(enb);
			grid(lteCellRSIndices(enb)) = lteCellRS(enb);
			
			% Synchronization
			grid(ltePSSIndices(enb)) = ltePSS(enb);
			grid(lteSSSIndices(enb)) = lteSSS(enb);
			
			obj.Ref.ReGrid = grid;
			[obj.Ref.Waveform, obj.Ref.WaveformInfo] = lteOFDMModulate(enb,grid);
		end
		
		function obj = assignReferenceSubframe(obj)
			obj.Waveform = obj.Ref.Waveform;
			obj.ReGrid = obj.Ref.ReGrid;
			obj.WaveformInfo = obj.Ref.WaveformInfo;
		end
    
    function EIRPSubcarrier = getEIRPSubcarrier(obj)
      % Returns EIRP per subcarrier in Watts
      EIRPSubcarrier = obj.getEIRP()/size(obj.ReGrid,1);
		end
		
    
    function EIRP = getEIRP(obj)
      % Returns EIRP in Watts
      EIRP = 10^((obj.getEIRPdBm())/10)/1000;
    end
    
		function EIRPdBm = getEIRPdBm(obj, TxPosition, RxPosition)
			% TODO: finalize antenna mapping and get gain from the correct panel/element
			AntennaGains = obj.AntennaArray.getAntennaGains(TxPosition, RxPosition);
      EIRPdBm = obj.TxPwdBm + obj.Gain - obj.NoiseFigure - AntennaGains{1};
    end
    
    % Methods
    % set BCH
    function obj = setBCH(obj)
      enb = struct(obj.Enb);
      mib = lteMIB(enb);
      bchCoded = lteBCH(enb, mib);
      obj.PBCH = struct('bch', bchCoded, 'unit', 1);
    end
    
    % Set default subframe resource grid
    function obj = resetResourceGrid(obj)
      enb = struct(obj.Enb);
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
      if (mod(enb.NSubframe, 10) == 0 && obj.PBCH.unit <= 4)
        fullPbch = ltePBCH(enb,obj.PBCH.bch);
        indPbch = ltePBCHIndices(enb);
        
        % find which portion of the PBCH we need to send in this frame and insert
        a = (obj.PBCH.unit - 1) * length(indPbch) + 1;
        b = obj.PBCH.unit * length(indPbch);
        pbch = fullPbch(a:b, 1);
        regrid(indPbch) = pbch;
        
        % finally update the unit counter
        obj.PBCH.unit = obj.PBCH.unit + 1;
      end
      
      % Write back into the objects
      obj.PBCH = obj.PBCH;
      obj.ReGrid = regrid;
    end
    
    % Reset transmitter
    function obj = reset(obj, nextSchRound)
      % every 40 ms the cell has to broadcast its identity with the BCH
      % check if we need to regenerate that
      if mod(nextSchRound, 40) == 0
        obj.setBCH();
      end
      
      % Reset the grid and put in the grid RS, PSS and SSS
      obj.resetResourceGrid();
      
      % Reset the waveform and the grid transmitted
      obj.Waveform = [];
      obj.WaveformInfo = [];
    end
    
		function obj = modulateTxWaveform(obj)
			% modulateTxWaveform
			%
			% :param obj: enbTransmitterModule instance
			% :returns obj: enbTransmitterModule instance
			%

      enb = struct(obj.Enb);
      % Add PDCCH and generate a random codeword to emulate the control info carried
      pdcchParam = ltePDCCHInfo(enb);
      ctrl = randi([0,1],pdcchParam.MTot,1);
      [pdcchSym, pdcchInfo] = ltePDCCH(enb,ctrl);
      indPdcch = ltePDCCHIndices(enb);
      obj.ReGrid(indPdcch) = pdcchSym;
      % Assume lossless transmitter
      [obj.Waveform, obj.WaveformInfo] = lteOFDMModulate(enb, obj.ReGrid);
      % set in the WaveformInfo the percentage of OFDM symbols used for this subframe
      % for power scaling
      used = length(find(abs(obj.ReGrid) ~= 0));
      obj.WaveformInfo.OfdmEnergyScale = used/numel(obj.ReGrid);
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
    
    
		function obj = setPDSCHGrid(obj, syms)
			% setPDSCHGrid insert PDSCH symbols in grid at correct indexes
			% 
			% :param obj: enbTransmitterModule instance
			% :param syms: Array of complex symbols
			% :returns: enbTransmitterModule instance
			%

			enb = struct(obj.Enb);
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
		function obj = initPDSCH(obj)
			NDLRB = obj.Enb.NDLRB;
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
