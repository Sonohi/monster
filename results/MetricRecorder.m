classdef MetricRecorder
	properties 
		infoUtilLo;
		infoUtilHi;
		util;
		power;
		schedule;
		harqRtx;
		arqRtx;
		ber;
		snr;
		snrdB;
		sinr;
		sinrdB
		bler;
		cqi;
		preEvm;
		postEvm;
		throughput;
	end

	methods 
		% Constructor
		function obj = MetricRecorder(Param, utilLo, utilHi)
			% Store utilisation thresholds for information
			obj.infoUtilLo = utilLo;
			obj.infoUtilHi = utilHi;
			% Initialise for eNodeB
			obj.util = zeros(Param.schRounds, Param.numMacro + Param.numMicro);
			obj.power = zeros(Param.schRounds, Param.numMacro + Param.numMicro);
			temp(1:Param.schRounds, Param.numMacro + Param.numMicro, 1:Param.numSubFramesMacro) = struct('UeId', -1, 'Mcs', -1, 'ModOrd', -1);
			obj.schedule = temp;			
			
			%zeros(Param.schRounds, Param.numMacro + Param.numMicro, Param.numSubFramesMacro);
			obj.harqRtx = zeros(Param.schRounds, Param.numMacro + Param.numMicro);
			obj.arqRtx = zeros(Param.schRounds, Param.numMacro + Param.numMicro);

			% Initialise for UE
			obj.ber = zeros(Param.schRounds,Param.numUsers);
			obj.snr = zeros(Param.schRounds,Param.numUsers);
			obj.sinr = zeros(Param.schRounds,Param.numUsers);
			obj.bler = zeros(Param.schRounds,Param.numUsers);
			obj.cqi = zeros(Param.schRounds,Param.numUsers);
			obj.preEvm = zeros(Param.schRounds,Param.numUsers);
			obj.postEvm = zeros(Param.schRounds,Param.numUsers);
			obj.throughput = zeros(Param.schRounds,Param.numUsers);
			
		end


		% eNodeB metrics
		function obj = recordEnbMetrics(obj, Stations, schRound)
			% Increment the scheduling round for Matlab's indexing
			schRound = schRound + 1;
			obj = obj.recordUtil(Stations, schRound);
			obj = obj.recordPower(Stations, schRound);
			obj = obj.recordSchedule(Stations, schRound);
		end
		
		function obj = recordUtil(obj, Stations, schRound)
			for iStation = 1:length(Stations)
				sch = find([Stations(iStation).ScheduleDL.UeId] ~= -1);
				utilPercent = 100*find(sch, 1, 'last' )/length(sch);
		
				% check utilPercent and change to 0 if null
				if isempty(utilPercent)
					utilPercent = 0;
				end

				obj.util(schRound, iStation) = utilPercent;
			end
		end

		function obj = recordPower(obj, Stations, schRound)
			for iStation = 1:length(Stations)
				if ~isempty(obj.util(schRound, iStation))
					pIn = getPowerIn(Stations(iStation), obj.util(schRound, iStation)/100);
					obj.power(schRound, iStation) = pIn;
				else	
					sonohilog('Power consumed cannot be recorded. Please call recordUtil first.','ERR')
				end
			end
		end

		function obj = recordSchedule(obj, Stations, schRound)
			for iStation = 1:length(Stations)
				numPrbs = length(Stations(iStation).ScheduleDL);
				obj.schedule(schRound, iStation, 1:numPrbs) = Stations(iStation).ScheduleDL;
			end
		end


		% UE metrics
		function obj = recordUeMetrics(obj, Users, schRound)
			% Increment the scheduling round for Matlab's indexing
			schRound = schRound + 1;
			obj = obj.recordBer(Users, schRound);
			obj = obj.recordBler(Users, schRound);
			obj = obj.recordSnr(Users, schRound);
			obj = obj.recordSinr(Users, schRound);
			obj = obj.recordCqi(Users, schRound);
			obj = obj.recordEvm(Users, schRound);
			obj = obj.recordThroughput(Users, schRound);
		end

		function obj = recordBer(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.Bits) && Users(iUser).Rx.Bits.tot ~= 0
					obj.ber(schRound, iUser) = Users(iUser).Rx.Bits.err/Users(iUser).Rx.Bits.tot;
				end
			end
		end

		function obj = recordBler(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.Blocks) && Users(iUser).Rx.Blocks.tot ~= 0
					obj.bler(schRound, iUser) = Users(iUser).Rx.Blocks.err/Users(iUser).Rx.Blocks.tot;
				end
			end
		end

		function obj = recordSnr(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.SNR)
					obj.snr(schRound, iUser) = Users(iUser).Rx.SNR;
					obj.snrdB(schRound, iUser) = 10*log10(Users(iUser).Rx.SNR);
				end
			end
		end

		function obj = recordSinr(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.SINR)
					obj.sinr(schRound, iUser) = Users(iUser).Rx.SINR;
					obj.sinrdB(schRound, iUser) = 10*log10(Users(iUser).Rx.SINR);
				end
			end
		end

		function obj = recordCqi(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.CQI)
					obj.cqi(schRound, iUser) = Users(iUser).Rx.CQI;
				end
			end
		end

		function obj = recordEvm(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.PreEvm)
					obj.preEvm(schRound, iUser) = Users(iUser).Rx.PreEvm;
				end
				if ~isempty(Users(iUser).Rx.PostEvm)
					obj.postEvm(schRound, iUser) = Users(iUser).Rx.PostEvm;
				end
			end
		end

		function obj = recordThroughput(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.Bits)
					obj.throughput(schRound, iUser) = Users(iUser).Rx.Bits.ok*10e3;
				end
			end
		end

	end
end