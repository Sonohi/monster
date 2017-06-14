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
		BsClass;
		Freq;
		Active;
		Neighbours;
	end

	methods
		% Constructor
		function obj = EvolvedNodeB(Param, BsClass, cellId)
			switch BsClass
				case 'macro'
					obj.NDLRB = Param.numSubFramesMacro;
				case 'micro'
					obj.NDLRB = Param.numSubFramesMicro;
            end
            obj.BsClass = BsClass;
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
            obj.Freq = Param.freq;
			obj = resetSchedule(obj);
			obj = resetResourceGrid(obj);
			obj = initPDSCH(obj);
			obj.Active = 1;
			obj.Neighbours = zeros(1, Param.numMacro + Param.numMicro);
		end

		% Posiiton base station
		function obj = setPosition(obj, pos)
			obj.Position = pos;
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
      % Assume lossless transmitter
			[obj.TxWaveform, obj.WaveformInfo] = lteOFDMModulate(enb, enb.ReGrid);
      obj.WaveformInfo.SNR = 40;
		end

		% create list of neighbours
		function obj = setNeighbours(obj, Stations, Param)
			% the macro eNodeB has neighbours all the micro
			if obj.BsClass == 'macro'
				obj.Neighbours(1:Param.numMicro) = find([Stations.NCellID] ~= obj.NCellID);
			% the micro eNodeBs only get the macro as neighbour and all the micro eNodeBs
			% in a circle of radius Param.nboRadius
			else
				for iStation = 1:length(Stations)
					if Stations(iStation).BsClass == 'macro'
						% insert in array at lowest index with 0
						ix = min(find(not(obj.Neighbours)));
						obj.Neighbours(ix) = Stations(iStation).NCellID;
					elseif Stations(iStation).NCellID ~= obj.NCellID
						pos = obj.Position(1:2);
						nboPos = Stations(iStation).Position(1:2);
						dist = pdist(cat(1, pos, nboPos));
						if dist <= Param.nboRadius
							ix = min(find(not(obj.Neighbours)));
							obj.Neighbours(ix) = Stations(iStation).NCellID;
						end
					end
				end
			end

		end

		% cast object to struct
		function enbStruct = cast2Struct(obj)
			enbStruct = struct(obj);
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



	end
end
