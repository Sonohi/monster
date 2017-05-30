%   EVOLVED NODE B defines a value class for creating and working with eNodeBs

classdef EvolvedNodeB
	%   EVOLVED NODE B defines a value class for creating and working with eNodeBs
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
    WaveformInfo;
		PDSCH;
		Channel;
		NSubframe;
	end

	methods
		% Constructor
		function obj = EvolvedNodeB(Param, bsClass, cellId)
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
      obj.Windowing = 0;
			obj.DuplexMode = 'FDD';
			obj.RrNext = struct('UeId',0,'Index',1);
			obj.TxWaveform = zeros(obj.NDLRB * 307.2, 1);
			obj.Users = zeros(Param.numUsers, 1);
			obj = resetSchedule(obj);
			obj = resetResourceGrid(obj);
			obj = initPDSCH(obj);
      % Construct channel
      obj.Channel = ChBulk_v1(Param);
		end

		% Posiiton base station
		function obj = setPosition(obj, pos)
			obj.Position = pos;
      % Set position for channel configuration.
      obj.Channel.Tx_pos = pos;
    end

		% reset users
		function obj = resetUsers(obj, Param)
			obj.Users = zeros(Param.numUsers, 1);
		end

		% reset schedule
		function obj = resetSchedule(obj)
			temp(1:obj.NDLRB,1) = struct('UeId', 0, 'Mcs', 0, 'ModOrd', 0);
			obj.Schedule = temp;
		end

		% set subframre number
		function obj = set.NSubframe(obj, num)
			obj.NSubframe =  num;
		end

		% Set resource grid for eNodeB
		function obj = resetResourceGrid(obj)
			str = lteDLResourceGrid(cast2Struct(obj));
			obj.ReGrid = str;
		end

		% modulate TX waveform
		function obj = modulateTxWaveform(obj)
			enb = cast2Struct(obj);
			[obj.TxWaveform, obj.WaveformInfo] = lteOFDMModulate(enb, enb.ReGrid);
		end

	end

	methods (Access = private)
		% set PDSCH
		function obj = initPDSCH(obj)
			ch = struct('TxScheme', 'Port0', 'Modulation', {'QPSK'}, 'NLayers', 1, ...
				'Rho', -3, 'RNTI', 1, 'RVSeq', [0 1 2 3], 'RV', 0, 'NHARQProcesses', 8, ...
				'NTurboDecIts', 5, 'PRBSet', (0:obj.NDLRB-1)', 'TrBlkSizes', [], ...
				'CodedTrBlkSizes', [], 'CSIMode', 'PUCCH 1-0', 'PMIMode', 'Wideband', 'CSI', 'On');
			obj.PDSCH = ch;
		end

		% cast object to struct
		function enbStruct = cast2Struct(obj)
			enbStruct = struct(obj);
		end

	end
end
