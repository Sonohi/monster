classdef ueTransmitterModule < matlab.mixin.Copyable
	properties
		PRACH;
		PRACHInfo;
		Waveform;
		WaveformInfo;
		ReGrid;
		Ref; % Resource grid for reference signals
		PUCCH;
		PUSCH;
		Freq; % Operating frequency.
		TxPwdBm; % Transmission power (Power class)
		Gain = 4; % Antenna gain
		UeObj;
		HarqActive;
		SRSActive;
		SRSConfig;
	end
	
	methods
		
		function obj = ueTransmitterModule(UeObj, Config)
			obj.Freq = Config.Phy.uplinkFrequency;
			obj.PUCCH.Format = Config.Phy.pucchFormat;
			obj.PRACH.Interval = Config.Phy.prachInterval;
			obj.PRACH.Format = 0;          % PRACH format: TS36.104, Table 8.4.2.1-1, CP length of 0.10 ms, typical cell range of 15km
			obj.PRACH.SeqIdx = 22;         % Logical sequence index: TS36.141, Table A.6-1
			obj.PRACH.CyclicShiftIdx = 1;  % Cyclic shift index: TS36.141, Table A.6-1
			obj.PRACH.HighSpeed = 0;       % Normal mode: TS36.104, Table 8.4.2.1-1
			obj.PRACH.FreqOffset = 0;      % Default frequency location
			obj.PRACH.PreambleIdx = 32;    % Preamble index: TS36.141, Table A.6-1
			obj.PRACHInfo = ltePRACHInfo(UeObj, obj.PRACH);
			obj.PUSCH = struct(...
				'Active', 1,...
				'Modulation', 'QPSK',...
				'PRBSet', [0:5].',...
				'NLayers', 1,...
				'TrBlkSizes',1);
			obj.UeObj = UeObj;
			obj.HarqActive = Config.Harq.active;
			obj.SRSActive = Config.SRS.active;
			obj.TxPwdBm = 23;
			obj.resetRef();
			obj.SRSConfig = struct('CSRS', 7, 'BSRS', 0, 'subframeConfig',0, 'ConfigIdx', 15, 'FreqPosition', 0);
		end
		
		function obj = setPRACH(obj, ueObj, NSubframe)
			obj.PRACH.TimingOffset = obj.PRACHInfo.BaseOffset + NSubframe/10.0;
			obj.Waveform = ltePRACH(ueObj, obj.PRACH);
		end

		function EIRPdBm = getEIRPdBm(obj)
			% Returns EIRP
			EIRPdBm = obj.TxPwdBm + obj.Gain;

		end

		function obj = setupTransmission(obj)
			% Setup the transmission chain of the UE transmitter
			% 1. Setup resource grid
			% 2. Setup necessary control signals
			% 3. Add data (missing)
			% 4. Modulate resource grid into waveform
			%
			% Returns updated :obj.ReGrid:, :obj.Waveform:, :obj.WaveformInfo:	
			
			% Setup the dimensions for transmission
			obj.setupResourceGrid();

			% Setup the control signals
			obj.setupControlSignals();

			% TODO: add actual data here
			if obj.UeObj.Scheduled.UL & obj.PUSCH.Active == 1
				obj.setupPUSCH();
			end

			% Modulate the resource grid
			obj.modulateResourceGrid();

		end

		function bits = generatePUSCHBits(obj)

			% Get transport block size
			bits = randi([0,1],obj.PUSCH.TrBlkSizes(1),1);


		end

		function obj = setupPUSCH(obj)

			% 1. Generate information bits for the PUSCH
			%bits = obj.generatePUSCHBits();

			% 2. Apply coding chain
			%cw = lteULSCH(struct(obj.UeObj), obj.PUSCH, bits);

			% 3. Generate PUSCH symbols
			%puschSym = ltePUSCH(struct(obj.UeObj),obj.pusch,cw);

			% 4. Add to resource grid
		end

		function obj = setupResourceGrid(obj)
			% Setup the dimensions of the resource grid to be modulation. 
			% Overwrites the dimensions and content of any preassigned resource grid.
			%
			% returns :obj.ReGrid: 
			if ~isempty(obj.ReGrid)
				obj.UeObj.Logger.log('Expecting empty resource grid. UE tx not reset between rounds.', 'ERR', 'ueTransmitterModule:ExpectedEmptyResourceGrid')
			end

			obj.ReGrid = lteULResourceGrid(struct(obj.UeObj));
			obj.Ref.Grid = obj.ReGrid; % Same structure for reference frame
		end

		function obj = setupControlSignals(obj)
			% Setup control signals. These include:
			% PUCCH
			% PUSCH
			% DRS
			% SRS
			%
			% Returns updated :obj.ReGrid:
			% Prepare payload with the latest CQI reporting.
			% Currently that only includes the wideband reporting
			cqiBits = de2bi(obj.UeObj.Rx.CQI.wideBand, 4, 'left-msb')';
			zeroPad = zeros(11,1);
			if (obj.HarqActive && isempty(obj.UeObj.Rx.TransportBlock)) || ~obj.HarqActive
				reportHarqBit = 0;
				harqBits = int8(zeros(4,1));
			elseif obj.HarqActive
				reportHarqBit = 1;
				harqAck = obj.UeObj.Mac.HarqReport.ack;
				harqPid = obj.UeObj.Mac.HarqReport.pid;
				harqBits = cat(1, harqPid, harqAck);
			end

			pucch2Bits = cat(1, reportHarqBit, zeroPad, cqiBits, harqBits);
			
			chs.ResourceIdx = 0;
			switch obj.PUCCH.Format
				case 2
					obj.PUCCH.Bits = pucch2Bits;
					obj.PUCCH.Symbols = ltePUCCH2(struct(obj.UeObj),chs,pucch2Bits);
					obj.PUCCH.Indices = ltePUCCH2Indices(struct(obj.UeObj),chs);
					pucchDRSIdx = ltePUCCH2DRSIndices(struct(obj.UeObj), chs);
					pucchDRS = ltePUCCH2DRS(struct(obj.UeObj), chs, harqBits(3:end));
			end
			
			obj.ReGrid(obj.PUCCH.Indices) = obj.PUCCH.Symbols;
			obj.ReGrid(pucchDRSIdx) = pucchDRS;

			% Store reference in seperate grid for channel estimator
			obj.Ref.Grid(pucchDRSIdx) = pucchDRS;
			obj.Ref.pucchDRSIdx = pucchDRSIdx;

			obj.setupPUSCHDRS();
			if obj.SRSActive
				obj.setupSRS();
			end

		end
		


		function [srs, srsInfo] = setupSRSConfig(obj, CSRS, BSRS, subframeConfig, ConfigIdx, FreqPosition)
			% Config for SRS
			%
			% C_SRS defines the cell specific SRS bandwidth
			% B_SRS defines the UE specific SRS bandwidth
			% SubframeConfig defines the periodicity of the SRS sequence
			srs = struct;
			srs.NTxAnts = 1; % TODO: Get number of Tx antennas
			srs.HoppingBW =3;      % SRS frequency hopping configuration
			srs.TxComb =0;         % Even indices for comb transmission
			srs.FreqPosition = FreqPosition;   % Frequency domain position
			srs.CyclicShift = 0;    % UE-cyclic shift
			srs.BWConfig = CSRS;       % Cell-specific SRS bandwidth configuration C_SRS
			srs.BW = BSRS;             % UE-specific SRS bandwidth configuration  B_SRS
			srs.SubframeConfig = subframeConfig;
			srs.ConfigIdx = ConfigIdx;
			
			srsInfo = lteSRSInfo(obj.UeObj, srs);     
		end

		function obj = setupSRS(obj)
			% Add SRS symbols to the grid
			[CSRS, BSRS, subframeConfig, ConfigIdx, FreqPosition] = obj.selectSRSConfig();
			
			[srs, srsInfo] = obj.setupSRSConfig(CSRS, BSRS, subframeConfig, ConfigIdx, FreqPosition);
			% Configure SRS sequence according to TS
			% 36.211 Section 5.5.1.3 with group hopping disabled
			srs.SeqGroup = mod(obj.UeObj.NCellID,30);

			% Configure the SRS base sequence number (v) according to TS 36.211
			% Section 5.5.1.4 with sequence hopping disabled
			srs.SeqIdx = 1;

			% Generate and map SRS to resource grid
			% (if active under UE-specific SRS configuration)
			if srsInfo.IsSRSSubframe
				[srsIdx, ~] = lteSRSIndices(obj.UeObj, srs);% SRS indices
				
				SRSSymbols = lteSRS(obj.UeObj, srs);
				
				% Store seperately for channel estimation
				obj.Ref.Grid(srsIdx) = SRSSymbols;
				obj.Ref.srsIdx = srsIdx;

				% Insert into resource grid
				obj.ReGrid(srsIdx) = SRSSymbols;
			else
				obj.Ref.srsIdx = [];
			end

		end
	
		function [CSRS, BSRS, subframeConfig, ConfigIdx, FreqPosition] = selectSRSConfig(obj)
			% Select configuration of SRS sequence
			%
			% TODO: Add scheme for selecting SRS configuration based on higher
			% layer protocol messages.
			%
			% Per table 8.2-4 in 36213 for FDD
			% MATLAB uses a different table allocation (maybe a prior release),
			% thus the mapping of subframeConfig is
			% 0 = 1 ms
			% 1-2 = 2 ms
			% 3-8 = 5 ms
			% 9-14 = 10 ms
			% 15 = 1 ms
			CSRS = obj.SRSConfig.CSRS;
			BSRS = obj.SRSConfig.BSRS;
			subframeConfig = obj.SRSConfig.subframeConfig;
			ConfigIdx = obj.SRSConfig.ConfigIdx;
			FreqPosition = obj.SRSConfig.FreqPosition;
			
			
		end


		function obj = setupPUSCHDRS(obj)
			% Setup DRS sequence
			% 
			% Returns updated :obj.ReGrid:
			puschdrsSeq = ltePUSCHDRS(struct(obj.UeObj),obj.PUSCH);
			puschDRSIdx = ltePUSCHDRSIndices(struct(obj.UeObj),obj.PUSCH);
			obj.ReGrid(puschDRSIdx) = puschdrsSeq;
			obj.Ref.Grid(puschDRSIdx) = puschdrsSeq;
			obj.Ref.puschDRSIdx = puschDRSIdx;

		end


		function obj = modulateResourceGrid(obj)
			% Modulate resource grid to SCFDMA
			%
			% Returns updated :obj.Waveform: and :obj.WaveformInfo:
			if isempty(obj.ReGrid)
				obj.UeObj.Logger.log('Empty subframe in transmitter?','ERR','MonsterUeTransmitterModule:EmptySubframe')
			end

			[obj.Waveform, obj.WaveformInfo] = lteSCFDMAModulate(obj.UeObj,obj.ReGrid);
		end
	
		% Utility to reset the UE transmitter module between rounds
		function obj = reset(obj)
			obj.Waveform = [];
			obj.ReGrid = [];
			obj.resetRef();

		end	

		function obj = resetRef(obj)
			% Reset reference
			obj.Ref = struct(); %
			obj.Ref.Grid = [];
			obj.Ref.srsIdx = [];
			obj.Ref.pucchDRSIdx = [];
			obj.Ref.puschDRSIdx = [];
		end
		
	end
	
end
