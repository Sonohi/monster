classdef MetricRecorder
	properties 
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
		function obj = MetricRecorder(Param)
			% Initialise for eNodeB
			obj.util = zeros(Param.schRounds, Param.numMacro + Param.numMicro);
			obj.power = zeros(Param.schRounds, Param.numMacro + Param.numMicro);
			obj.schedule = zeros(Param.schRounds, Param.numMacro + Param.numMicro, Param.numSubFramesMacro);
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
				obj.schedule(schRound, iStation) = Stations(iStation).ScheduleDL;
			end
		end


		% UE metrics
		function obj = recordBer(obj, Users, schRound)
			for iUser = 1:length(Users)
				if Users(iUser).Rx.Bits.tot ~= 0
					obj.ber(schRound, iUser) = Users(iUser).Rx.Bits.err/Users(iUser).Rx.Bits.tot;
				end
			end
		end

		function obj = recordBler(obj, Users, schRound)
			for iUser = 1:length(Users)
				if Users(iUser).Rx.Blocks.tot ~= 0
					obj.ber(schRound, iUser) = Users(iUser).Rx.Blocks.err/Users(iUser).Rx.Blocks.tot;
				end
			end
		end

		function obj = recordSnr(obj, Users, schRound)
			for iUser = 1:length(Users)
				if Users(iUser).Rx.Blocks.tot ~= 0
					obj.ber(schRound, iUser) = Users(iUser).Rx.Blocks.err/Users(iUser).Rx.Blocks.tot;
				end
			end
		end

	end
end