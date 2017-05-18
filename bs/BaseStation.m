%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   BASE STATION defines a class for eNodeB
%
% 	Properties
%
%		Methods
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef BaseStation < handle
	properties
		NCellID;
		DuplexMode;
		Position;
		NDLRB;
		CellRefP;
		CyclicPrefix;
		CFI;
		PHICHDuration;
		Ng;
		NFrame;
		TotSubframes;
		OCNG;
		Windowing;
		Users;
		Schedule;
		RrNext;
		ReGrid;
		TxWaveform;
		PDSCH;
	end

	methods
		% Constructor
		function obj = BaseStation(Param, bsClass, cellId)
			switch bsClass
				case 'macro'
					obj.NDLRB = Param.numSubFramesMacro;
				case 'micro'
					obj.NDLRB = Param.numSubFramesMicro;
			end
			obj.NCellID = cellId;
			obj.CellRefP = 1;
			obj.CyclicPrefix = 'Normal';
			obj.CFI = 2;
			obj.PHICHDuration = 'Normal';
			obj.Ng = 'Sixth';
			obj.NFrame = 0;
			obj.TotSubframes = 1;
			obj.OCNG = 'On';
			obj.DuplexMode = 'FDD';
			obj.RrNext = struct('ueId',0,'index',1);
			obj.TxWaveform = zeros(obj.NDLRB * 307.2, 1);
			obj = initUsers(obj, Param);
			obj = initSchedule(obj);
			obj = initSchedule(obj);
			obj = initResourceGrid(obj);
			obj = initPDSCH(obj);
		end

		% Posiiton base station
		function obj = set.Position(obj, pos)
			obj.Position = pos;
		end

	end

	methods (Access = private)
		% Set resource grid for eNOdeB
		function obj = initResourceGrid(obj)
			str = lteDLResourceGrid(struct(obj));
			obj.ReGrid = str;
			
		end

		% set PDSCH
		function obj = initPDSCH(obj)
			ch = struct('TxScheme', 'Port0', 'Modulation', {'QPSK'}, 'NLayers', 1, ...
				'Rho', -3, 'RNTI', 1, 'RVSeq', [0 1 2 3], 'RV', 0, 'NHARQProcesses', 8, ...
				'NTurboDecIts', 5, 'PRBSet', (0:obj.NDLRB-1)', 'TrBlkSizes', [], ...
				'CodedTrBlkSizes', [], 'CSIMode', 'PUCCH 1-0', 'PMIMode', 'Wideband', 'CSI', 'On');
			obj.PDSCH = ch;
		end

		% init users
		function obj = initUsers(obj, Param)
			temp(1:Param.numUsers) = struct('velocity', Param.velocity,...
				'queue', struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0, 'scheduled', ...
				false, 'ueId', 0, 'position', [0 0], 'wCqi',6);
			obj.Users = temp;
		end

		% init schedule
		function obj = initSchedule(obj)
			temp(1:obj.NDLRB,1) = struct('ueId', 0, 'mcs', 0, 'modOrd', 0);
			obj.Schedule = temp;
		end

	end
end
