classdef MetricRecorder
	properties 
		util;
		power;
		schedule;
		harqRtx;
		arqRtx;
		ber;
		snr;
		sinr;
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
	end
end