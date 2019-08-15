classdef enbTransmitterModule < matlab.mixin.Copyable
	properties
		% Parent eNB object
		Enb;
		
		% Structure containing necessary reference signals/grids
		Ref;
		
		% Resource Grid to be modulated
		ReGrid;
		
		% Modulated waveform and waveform info. Used for transmission
		Waveform;
		WaveformInfo;
		
		% Control channel
		PBCH;

		% Shared data channel
		PDSCH;
				
		% Physical properties
		TxPwdBm;
		NoiseFigure;
		Gain;
		Freq;
		AntennaArray;
		AntennaType;
	end
	
	methods
		function obj = enbTransmitterModule(enb, Config, antennaBearing)
			% enbTransmitterModule
			%
			% :param enb:
			% :param Config:
			% :returns obj:
			%
			
			obj.Enb = enb;

			switch enb.BsClass
				case 'macro'
					obj.Gain = Config.MacroEnb.antennaGain;
					obj.NoiseFigure = Config.MacroEnb.noiseFigure;
					obj.AntennaArray = AntennaArray(Config.MacroEnb.antennaType, obj.Enb.Logger);
					obj.TxPwdBm = 10*log10(Config.MacroEnb.Pmax)+30;
					if ~strcmp(Config.MacroEnb.antennaType, 'omni')
						obj.AntennaArray.Bearing = antennaBearing;
					end
				case 'micro'
					obj.Gain = Config.MicroEnb.antennaGain;
					obj.NoiseFigure = Config.MicroEnb.noiseFigure;
					obj.AntennaArray = AntennaArray(Config.MicroEnb.antennaType, obj.Enb.Logger);
					obj.TxPwdBm = 10*log10(Config.MicroEnb.Pmax)+30;
					if ~strcmp(Config.MicroEnb.antennaType, 'omni')
						obj.AntennaArray.Bearing = antennaBearing;
					end
				otherwise
					obj.Enb.Logger.log(sprintf('(ENODEB TRANSMITTER - constructor) eNodeB %i has an invalid base station class %s', enb.NCellID, enb.BsClass), 'ERR');
			end

			Nfft = 2^ceil(log2(12*enb.NDLRB/0.85));
			obj.Waveform = zeros(Nfft, 1);
			obj.resetReference();
			obj.resetResourceGrid();
			obj.setupGrid(0);
			obj.initPDSCH();
			obj.Freq = Config.Phy.downlinkFrequency;
		end
		
		function setupGrid(obj, schRound)
			% Setup grid using the following procedure
			% 1. Every 40ms the BCH is needed.
			% 2. Reset previous grid and the content
			% 3. Set the resource grid for the current round with necessary reference signals.
			%
			% The call of this function enables use of adding Codewords and modulating the final waveform
			obj.reset();
			
			if mod(schRound, 40) == 0
				obj.setBCH();
			end
			
			% Set the grid and put in the grid RS, PSS and SSS
			obj.setResourceGrid();
			
		end
		
		function obj = reset(obj)
			% Clear reference and resource grid
			obj.resetReference();
			obj.resetResourceGrid();
			
			% Reset the waveform and the grid transmitted
			obj.Waveform = [];
			obj.WaveformInfo = [];
		end
		
		function obj = resetResourceGrid(obj)
			obj.ReGrid = [];
		end
		
		function resetReference(obj)
			obj.Ref = struct('ReGrid',[], 'Waveform',[], 'WaveformInfo',[],'PSSInd',[],'PSS', [],'SSS', [],'SSSInd',[],'PSSWaveform',[], 'SSSWaveform',[]);
		end
		
		function grid = getEmptyResourceGrid(obj)
			% Returns an empty resource grid based on the eNB parameters.
			%
			% Returns :grid: NxM Matrix
			enb = struct(obj.Enb);
			grid = lteResourceGrid(enb);
		end
		
		function createReferenceSubframe(obj)
			% Create reference subframe
			% Consists of the following pilot signals
			% PSS
			% SSS
			% CellRS
			% TODO: SRS (missing)
			%
			% Returns a constructed :obj.Ref:
			grid = obj.getEmptyResourceGrid();
			
			enb = struct(obj.Enb);
			
			% Synchronization
			PSS = ltePSS(enb);
			PSSInd = ltePSSIndices(enb);
			grid(PSSInd) = PSS;
			
			SSS = lteSSS(enb);
			SSSInd = lteSSSIndices(enb);
			grid(SSSInd) = SSS;
			
			% Cell Reference
			grid(lteCellRSIndices(enb, 0)) = lteCellRS(enb, 0);
			
			% Assign grid
			obj.Ref.ReGrid = grid;
			
			obj.Ref.PSS = PSS;
			obj.Ref.PSSInd = PSSInd;
			obj.Ref.SSS = SSS;
			obj.Ref.SSSInd = SSSInd;
			
			[obj.Ref.Waveform, obj.Ref.WaveformInfo] = lteOFDMModulate(enb,grid);
			
		end
		
		function obj = assignReferenceSubframe(obj)
			% Assign reference signals to current grid and waveform.
			%
			% Returns obj.Waveform, obj.ReGrid and obj.WaveformInfo;
			obj.Waveform = obj.Ref.Waveform;
			obj.ReGrid = obj.Ref.ReGrid;
			obj.WaveformInfo = obj.Ref.WaveformInfo;
		end
		
		function EIRP = getEIRP(obj)
			% Returns EIRP in Watts
			EIRP = 10^((obj.getEIRPdBm())/10)/1000;
		end
		
		function EIRPdBm = getEIRPdBm(obj, TxPosition, RxPosition)
			% Get EIRP of the transmitter module
			% It is a function of Transmission Power, Gain, Noise Figure and Antenna Gain
			% Transmission power is determined by the class of the eNB.
			% Gain is a figure to adjust the total EIRP
			% Noise figure is to account for cable loss and so on.
			% Antenna gain is the gain of the antenna element
			%
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
		
		function obj = setResourceGrid(obj)
			% Setup resource grid with reference signals and control signals
			%
			% Returns the setup of :obj.ReGrid: and :obj.PBCH:
			enb = struct(obj.Enb);
			
			obj.createReferenceSubframe();
			grid = obj.Ref.ReGrid;
			
			% Compute reference waveform of synchronization signals, used to compute offset
			obj = obj.computeReferenceWaveform();
			
			% Channel format indicator
			cfi = lteCFI(enb);
			indPcfich = ltePCFICHIndices(enb);
			pcfich = ltePCFICH(enb, cfi);
			
			% % put signals into the grid
			grid(indPcfich) = pcfich;
			
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
			obj.ReGrid = grid;
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
		
		function obj = computeReferenceWaveform(obj)
			% Compute and store reference waveforms of PSS and SSS, generated every 0th and 5th subframe
			if obj.Enb.NSubframe == 0 || obj.Enb.NSubframe == 5
				pssGrid = obj.getEmptyResourceGrid();
				pssGrid(obj.Ref.PSSInd) = obj.Ref.PSS;
				obj.Ref.PSSWaveform = lteOFDMModulate(struct(obj.Enb),pssGrid);
				sssGrid = obj.getEmptyResourceGrid();
				sssGrid(obj.Ref.SSSInd)=obj.Ref.SSS;
				obj.Ref.SSSWaveform = lteOFDMModulate(struct(obj.Enb),sssGrid);
			end
		end
		
		
		function obj = setPDSCHGrid(obj, syms, symsIxs)
			% setPDSCHGrid insert PDSCH symbols in grid at correct indexes
			%
			% :param obj: enbTransmitterModule instance
			% :param syms: Array of complex symbols
			% :param symsIxs: Array of PDSCH indexes for insertion in the grid
			% :returns: enbTransmitterModule instance
			%
			
			% Check that the indexes where these symbols should be instered are empty, otherwise throw an error
			if sum(obj.ReGrid(symsIxs) == 0)
				% pad for unused subcarriers
				padding(1:length(symsIxs) - length(syms), 1) = 0;
				syms = cat(1, syms, padding);
				
				% insert symbols into grid
				obj.ReGrid(symsIxs) = syms;
			else
				obj.Enb.Logger.log('(ENB TRANSMITTER - setPDSCHGrid) selected PDSCH indexes are not empty', 'ERR');
			end
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
