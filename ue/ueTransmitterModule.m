classdef ueTransmitterModule < matlab.mixin.Copyable
	properties
		PRACH;
		PRACHInfo;
		Waveform;
		WaveformInfo;
		ReGrid;
		PUCCH;
		PUSCH;
		Freq; % Operating frequency.
		TxPwdBm; % Transmission power (Power class)
		Gain = 4; % Antenna gain
		UeObj;
		HarqActive;
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
				'Active', 0,...
				'Modulation', 'QPSK',...
				'PRBSet', [],...
				'NLayers', 1);
			obj.UeObj = UeObj;
			obj.HarqActive = Config.Harq.active;
			%TODO: make configureable
			obj.TxPwdBm = 23;
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
			
			% Check whether this UE is scheduled in the UL
			if obj.UeObj.Scheduled.UL
				% Setup the dimensions for transmission
				obj.setupResourceGrid();

				% Setup the control signals
				obj.setupControlSignals();

				% TODO: add actual data here

				% Modulate the resource grid
				obj.modulateResourceGrid();
			end
		end

		function obj = setupResourceGrid(obj)
			% Setup the dimensions of the resource grid to be modulation. 
			% Overwrites the dimensions and content of any preassigned resource grid.
			%
			% returns :obj.ReGrid: 
			if ~isempty(obj.ReGrid)
				obj.ueObj.Logger('Expecting empty resource grid. UE tx not reset between rounds.', 'ERR', 'ueTransmitterModule:ExpectedEmptyResourceGrid')
			end

			obj.ReGrid = lteULResourceGrid(struct(obj.UeObj));
		end

		function obj = setupControlSignals(obj)
			% Setup control signals. These include:
			% PUCCH
			% PUSCH
			% DRS
			% SRS (optional)
			%
			% Returns updated :obj.ReGrid:
			cqiBits = de2bi(obj.UeObj.Rx.CQI, 4, 'left-msb')';
			zeroPad = zeros(11,1);
			if obj.HarqActive && isempty(obj.UeObj.Rx.TransportBlock) || ~obj.HarqActive
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
				case 1
					obj.PUCCH.Bits = harqAck;
					obj.PUCCH.Symbols = ltePUCCH1(struct(obj.UeObj),chs,harqAck);
					obj.PUCCH.Indices = ltePUCCH1Indices(struct(obj.UeObj),chs);
				case 2
					obj.PUCCH.Bits = pucch2Bits;
					obj.PUCCH.Symbols = ltePUCCH2(struct(obj.UeObj),chs,pucch2Bits);
					obj.PUCCH.Indices = ltePUCCH2Indices(struct(obj.UeObj),chs);
				case 3
					obj.PUCCH.Bits = pucch2Bits;
					obj.PUCCH.Symbols = ltePUCCH3(struct(obj.UeObj),chs,pucch2Bits);
					obj.PUCCH.Indices = ltePUCCH3Indices(struct(obj.UeObj),chs);
			end
			
			obj.ReGrid(obj.PUCCH.Indices) = obj.PUCCH.Symbols;
			obj.setupPUSCHDRS();
			obj.setupSRS();

		end

		function [srs, srsInfo] = setupSRSConfig(obj, C_SRS, B_SRS, SubframeConfig)
			% Config for SRS
			%
			% C_SRS defines the cell specific SRS bandwidth
			% B_SRS defines the UE specific SRS bandwidth
			% SubframeConfig defines the periodicity of the SRS sequence
			srs = struct;
			srs.NTxAnts = 1; % TODO: Get number of Tx antennas
			srs.HoppingBW = 0;      % SRS frequency hopping configuration
			srs.TxComb =0;         % Even indices for comb transmission
			srs.FreqPosition = 0;   % Frequency domain position
			srs.ConfigIdx = 0;      % UE-specific SRS period = 10ms, offset = 0
			srs.CyclicShift = 0;    % UE-cyclic shift
			srs.BWConfig = C_SRS;       % Cell-specific SRS bandwidth configuration C_SRS
			srs.BW = B_SRS;             % UE-specific SRS bandwidth configuration  B_SRS
			srs.SubframeConfig = SubframeConfig; % Change to 2 ms period
			srs.ConfigIdx = 0;
			srsInfo = lteSRSInfo(obj.ueObj, srs);     
		end

		function obj = setupSRS(obj)
			% Add SRS symbols to the grid
			
			[srs, srsInfo] = obj.setupSRSConfig(3, 3, 3);
			% Configure SRS sequence according to TS
			% 36.211 Section 5.5.1.3 with group hopping disabled
			srs.SeqGroup = mod(ue.NCellID,30);

			% Configure the SRS base sequence number (v) according to TS 36.211
			% Section 5.5.1.4 with sequence hopping disabled
			srs.SeqIdx = 1;

			% Generate and map SRS to resource grid
			% (if active under UE-specific SRS configuration)
			if srsInfo.IsSRSSubframe
				[srsIndices, ~] = lteSRSIndices(obj.ueObj, srs);% SRS indices
				obj.ReGrid(srsIndices) = lteSRS(obj.ueObj, srs);  
			end

		end



		function obj = setupPUSCHDRS(obj)
			% Setup DRS sequence
			% 
			% Returns updated :obj.ReGrid:
			puschdrsSeq = ltePUSCHDRS(struct(obj.UeObj),obj.PUSCH);
			puschdrsSeqind = ltePUSCHDRSIndices(struct(obj.UeObj),obj.PUSCH);
			obj.ReGrid(puschdrsSeqind) = puschdrsSeq;

		end

		function obj = modulateResourceGrid(obj)
			% Modulate resource grid to SCFDMA
			%
			% Returns updated :obj.Waveform: and :obj.WaveformInfo:
			[obj.Waveform, obj.WaveformInfo] = lteSCFDMAModulate(obj.UeObj,obj.ReGrid);
		end
	
		% Utility to reset the UE transmitter module between rounds
		function obj = reset(obj)
			obj.Waveform = [];
			obj.ReGrid = [];
		end	
		
	end
	
end
