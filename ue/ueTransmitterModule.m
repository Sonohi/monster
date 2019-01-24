classdef ueTransmitterModule < matlab.mixin.Copyable
	properties
		PRACH;
		PRACHInfo;
		Waveform;
		ReGrid;
		PUCCH;
		PUSCH;
	end
	
	methods
		
		function obj = ueTransmitterModule(ueObj, Config)
			obj.PUCCH.Format = Config.Phy.pucchFormat;
			obj.PRACH.Interval = Config.Phy.prachInterval;
			obj.PRACH.Format = 0;          % PRACH format: TS36.104, Table 8.4.2.1-1, CP length of 0.10 ms, typical cell range of 15km
			obj.PRACH.SeqIdx = 22;         % Logical sequence index: TS36.141, Table A.6-1
			obj.PRACH.CyclicShiftIdx = 1;  % Cyclic shift index: TS36.141, Table A.6-1
			obj.PRACH.HighSpeed = 0;       % Normal mode: TS36.104, Table 8.4.2.1-1
			obj.PRACH.FreqOffset = 0;      % Default frequency location
			obj.PRACH.PreambleIdx = 32;    % Preamble index: TS36.141, Table A.6-1
			obj.PRACHInfo = ltePRACHInfo(ueObj, obj.PRACH);
			obj.PUSCH = struct(...
				'Active', 0,...
				'Modulation', 'QPSK',...
				'PRBSet', [],...
				'NLayers', 1);
		end
		
		function obj = setPRACH(obj, ueObj, NSubframe)
			obj.PRACH.TimingOffset = obj.PRACHInfo.BaseOffset + NSubframe/10.0;
			obj.Waveform = ltePRACH(ueObj, obj.PRACH);
		end
		
		function [obj, reportHarqBit] = mapGridAndModulate(obj, ueObj, Config)
			% Check if upllink needs to consist of PRACH
			% TODO: changes to sequence and preambleidx given unique user ids
			%       if mod(ueObj.NSubframe, obj.PRACH.Interval) == 0
			%
			%          obj = obj.setPRACH(ueObj, ueObj.NSubframe);
			%
			%       else
			
			% PUCCH configuration
			% Format 1 is Scheduling request with/without bits for HARQ
			% Format 2 is CQI with/without bits for HARQ
			% Format 3 Bits for HARQ
			
			% Get HARQ and CQI info for this report from the MAC layer bits
			% We need to check whether HARQ feedback has to be sent or not
			cqiBits = de2bi(ueObj.Rx.CQI, 4, 'left-msb')';
			zeroPad = zeros(11,1);
			if Config.Harq.active && isempty(ueObj.Rx.TransportBlock) || ~Config.Harq.active
				reportHarqBit = 0;
				harqBits = int8(zeros(4,1));
			elseif Config.Harq.active
				reportHarqBit = 1;
				harqAck = ueObj.Mac.HarqReport.ack;
				harqPid = ueObj.Mac.HarqReport.pid;
				harqBits = cat(1, harqPid, harqAck);
			end
			
			pucch2Bits = cat(1, reportHarqBit, zeroPad, cqiBits, harqBits);
			
			chs.ResourceIdx = 0;
			switch obj.PUCCH.Format
				case 1
					obj.PUCCH.Bits = harqAck;
					obj.PUCCH.Symbols = ltePUCCH1(ueObj,chs,harqAck);
					obj.PUCCH.Indices = ltePUCCH1Indices(ueObj,chs);
				case 2
					obj.PUCCH.Bits = pucch2Bits;
					obj.PUCCH.Symbols = ltePUCCH2(ueObj,chs,pucch2Bits);
					obj.PUCCH.Indices = ltePUCCH2Indices(ueObj,chs);
				case 3
					obj.PUCCH.Bits = pucch2Bits;
					obj.PUCCH.Symbols = ltePUCCH3(ueObj,chs,pucch2Bits);
					obj.PUCCH.Indices = ltePUCCH3Indices(ueObj,chs);
			end
			
			reGrid = lteULResourceGrid(ueObj);
			reGrid(obj.PUCCH.Indices) = obj.PUCCH.Symbols;
			obj.ReGrid = reGrid;
			obj.Waveform = lteSCFDMAModulate(ueObj,obj.ReGrid);
			
			
			%         %% Configure PUSCH
			%         % TODO If we use RNTI
			%
			%         chs.Modulation = 'QPSK';
			%         chs.PRBSet = [0:obj.NULRB-1].';
			%         chs.RV = 0; %	Redundancy version (RV) indicator in initial subframe
			%
			%         % Reference data
			%         % TODO replace this with actual data
			%         frc = lteRMCUL('A1-1');
			%         trBlk  = randi([0,1],frc.PUSCH.TrBlkSizes(1),1);
			%         cw = lteULSCH(obj,chs,trBlk );
			%
			%         puschsym = ltePUSCH(obj,chs,cw);
			%         puschind = ltePUSCHIndices(obj,chs);
			%         puschdrsSeq = ltePUSCHDRS(obj,chs);
			%         puschdrsSeqind = ltePUSCHDRSIndices(obj,chs);
			%
			%         %% Configure SRS
			%         srssym = lteSRS(obj,chs);
			%         srsind = lteSRSIndices(obj,chs);
			%
			%         % Modulate SCFDMA
			%
			%         obj.ReGrid(pucchind) = pucchsym;
			%         obj.ReGrid(drsSeqind) = drsSeq;
			%         obj.ReGrid(puschind) = puschsym;
			%         obj.ReGrid(puschdrsSeqind) = puschdrsSeq;
			%         obj.ReGrid(srsind) = srssym;
			%
			%         % filler symbols
			%         %obj.ReGrid = reshape(lteSymbolModulate(randi([0,1],prod(dims)*2,1), ...
			%         %  'QPSK'),dims);
			%
			%         obj.Waveform = lteSCFDMAModulate(obj,obj.ReGrid);
			
			%end
		end
	
		% Utility to reset the UE transmitter module between rounds
		function obj = reset(obj)
			obj.Waveform = [];
			obj.ReGrid = [];
		end	
		
	end
	
end
