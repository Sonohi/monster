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
		Status;
		Neighbours;
		HystCount;
		Pmax;
		P0;
		DeltaP;
		Psleep;
	end

	methods
		% Constructor
		function obj = EvolvedNodeB(Param, BsClass, cellId)
			switch BsClass
				case 'macro'
					obj.NDLRB = Param.numSubFramesMacro;
					obj.Pmax = 20; % W
					obj.P0 = 130; % W
					obj.DeltaP = 4.7;
					obj.Psleep = 75; % W
				case 'micro'
					obj.NDLRB = Param.numSubFramesMicro;
					obj.Pmax = 6.3; % W
					obj.P0 = 56; % W
					obj.DeltaP = 2.6;
					obj.Psleep = 39.0; % W
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
			obj.NSubframe = 0;
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
			obj.Status = string('active');
			obj.Neighbours = zeros(1, Param.numMacro + Param.numMicro);
			obj.HystCount = 0;
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

		% Set default subframe resource grid for eNodeB
		function obj = resetResourceGrid(obj)
			enb = cast2Struct(obj);
			% Create empty grid
			regrid = lteDLResourceGrid(enb);
			% add RS in the right indexes
			indRs = lteCellRSIndices(enb, 0);
			rs = lteCellRS(enb, 0);
			% add synchronization signals
			indPss = ltePSSIndices(enb);
			pss = ltePSS(enb);
			indSss = lteSSSIndices(enb);
			sss = lteSSS(enb);
			% % put all 3 signals into the grid
			regrid(indRs) = rs;
			regrid(indPss) = pss;
			regrid(indSss) = sss;
			obj.ReGrid = regrid;
		end

		% insert PDSCH symbols in grid at correct indexes
		function obj = setPDSCHGrid(obj, syms)
			enb = cast2Struct(obj);
			% get PDSCH indexes
			indPdsch = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet);

			% pad for unused subcarriers
			padding(1:length(indPdsch) - length(syms), 1) = 0;
			syms = cat(1, syms, padding);

			% insert symbols into grid
			obj.ReGrid(indPdsch) = syms;
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
						ix = find(not(obj.Neighbours), 1 );
						obj.Neighbours(ix) = Stations(iStation).NCellID;
					elseif Stations(iStation).NCellID ~= obj.NCellID
						pos = obj.Position(1:2);
						nboPos = Stations(iStation).Position(1:2);
						dist = pdist(cat(1, pos, nboPos));
						if dist <= Param.nboRadius
							ix = find(not(obj.Neighbours), 1 );
							obj.Neighbours(ix) = Stations(iStation).NCellID;
						end
					end
				end
			end
		end

		% check utilisation wrapper
		function obj = checkUtilisation(obj, util, Param, loThr, hiThr, Stations)

			% overload
			if util >= hiThr
				obj.Status = string('overload');
				obj.HystCount = obj.HystCount + 1;
				if obj.HystCount >= Param.hystMax
					% The overload has exceeded the hysteresis guard, so find an inactive
					% neighbour that is micro to activate
					nboMicroIxs = find([obj.Neighbours] ~= Stations(1).NCellID);

					% Loop the neighbours to find an inactive one
					for iNbo = 1:length(nboMicroIxs)
						if nboMicroIxs(iNbo) ~= 0
							% find this neighbour in the stations
							nboIx = find([Stations.NCellID] == obj.Neighbours(nboMicroIxs(iNbo)));

							% Check if it can be activated
							if (~isempty(nboIx) && Stations(nboIx).Status == string('inactive'))
								Stations(nboIx).Status = string('active');
								Stations(nboIx).HystCount = 0;
								break;
							end
						end
					end
				end

			% underload
			elseif util <= loThr
				obj.HystCount = obj.HystCount + 1;
				if obj.HystCount >= Param.hystMax
					% the underload has exceeded the hysteresis guard, so change status
					obj.Status = string('inactive');
				end

			% normal operative range
			else
				obj.Status = string('active');
				obj.HystCount = 0;

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
