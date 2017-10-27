classdef enbTransmitterModule
	properties
		Waveform;
		WaveformInfo;
		ReGrid;
		PDSCH;
		PBCH;
		Frame;
		FrameInfo;
		FrameGrid;
	end

	methods
		% Constructor
		function obj = enbTransmitterModule(enb, Param)
			obj.Waveform = zeros(enb.NDLRB * 307.2, 1);
			obj = setBCH(obj, enb);
			obj = resetResourceGrid(obj, enb);
			obj = initPDSCH(obj, enb.NDLRB);
			[obj.Frame, obj.FrameInfo, obj.FrameGrid] = generateDummyFrame(enb);
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

		% map elements to grid and modulate waveform to transmit
		function obj = mapGridAndModulate(obj, enbObj, iStation, sym, Param)
			% the last step in the DL transmission chain is to map the symbols to the
			% resource grid and modulate the grid to get the TX waveform

			% extract all the symbols this eNodeB has to transmit
			symExtr = extractStationSyms(enbObj, iStation, sym, Param);

			% insert the symbols of the PDSCH into the grid
			obj = setPDSCHGrid(obj, enbObj, symExtr);

			% with the grid ready, generate the TX waveform
			obj = modulateTxWaveform(obj, enbObj);
		end

		% cast object to struct
		function txStruct = cast2Struct(obj)
			txStruct = struct(obj);
		end


	end

	methods (Access = private)
		% initialise PDSCH
		function obj = initPDSCH(obj, NDLRB)
			ch = struct(...
				'TxScheme', 'Port0',...
				'Modulation', {'QPSK'},...
				'NLayers', 1, ...
				'Rho', -3,...
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

		% modulate TX waveform
		function obj = modulateTxWaveform(obj, enbObj)
			enb = cast2Struct(enbObj);
			tx = cast2Struct(obj);
      % Assume lossless transmitter
			[obj.Waveform, obj.WaveformInfo] = lteOFDMModulate(enb, tx.ReGrid);
      obj.WaveformInfo.SNR = 40;
			% set in the WaveformInfo the percentage of OFDM symbols used for this subframe
			% for power scaling
			used = length(find(abs(tx.ReGrid) ~= 0));
			obj.WaveformInfo.OfdmEnergyScale = used/numel(tx.ReGrid);
		end

		% insert PDSCH symbols in grid at correct indexes
		function obj = setPDSCHGrid(obj, enbObj, syms)
			enb = cast2Struct(enbObj);
			regrid = obj.ReGrid;
			% get PDSCH indexes
			[indPdsch, pdschInfo] = ltePDSCHIndices(enb, obj.PDSCH, obj.PDSCH.PRBSet);

			% pad for unused subcarriers
			padding(1:length(indPdsch) - length(syms), 1) = 0;
			syms = cat(1, syms, padding);

			% insert symbols into grid
			regrid(indPdsch) = syms;

			% once the PDSCH is inserted, add also the PDDCH
			% generate a random codeword to emulate the control info carried
			pdcchParam = ltePDCCHInfo(enb);
			ctrl = randi([0,1],pdcchParam.MTot,1);
			[pdcchSym, pdcchInfo] = ltePDCCH(enb,ctrl);
			indPdcch = ltePDCCHIndices(enb);
			regrid(indPdcch) = pdcchSym;

			% Set back in object
			obj.ReGrid = regrid;

		end
	end

end
