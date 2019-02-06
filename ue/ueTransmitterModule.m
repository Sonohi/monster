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
		TxPwdBm = 23; % Transmission power (Power class)
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

			% Modulate the resource grid
			obj.modulateResourceGrid();
		end

		function obj = setupResourceGrid(obj)
			% Setup the dimensions of the resource grid to be modulation. 
			% Overwrites the dimensions and content of any preassigned resource grid.
			%
			% returns :obj.ReGrid: 
			if ~isempty(obj.ReGrid)
				MonsterLog('Expecting empty resource grid. UE tx not reset between rounds.', 'ERR', 'ueTransmitterModule:ExpectedEmptyResourceGrid')
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
