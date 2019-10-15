classdef MetricRecorder < matlab.mixin.Copyable
	% This is class is used for defining and recording statistics in the network
	properties
		infoUtilLo;
		infoUtilHi;
		util;
		powerConsumed;
		schedule;
		harqRtx;
		arqRtx;
		powerState;
		ber;
		snrdB;
		sinrdB;
		estsinrdB;
		bler;
		cqi;
		preEvm;
		postEvm;
		throughput;
		receivedPowerdBm;
		rsrqdB;
		rsrpdBm;
		rssidBm;
		Config;
	end
	
	methods
		% Constructor
		function obj = MetricRecorder(Config)
			% Store main config
			obj.Config = Config;
			% Store utilisation thresholds for information
			obj.infoUtilLo = Config.Son.utilLow;
			obj.infoUtilHi = Config.Son.utilHigh;
			% Initialise for eNodeB
			numEnodeBs = Config.MacroEnb.sitesNumber * Config.MacroEnb.cellsPerSite + Config.MicroEnb.sitesNumber * Config.MicroEnb.cellsPerSite;
			obj.util = zeros(Config.Runtime.totalRounds, numEnodeBs);
			obj.powerConsumed = zeros(Config.Runtime.totalRounds, numEnodeBs);
			temp(1:Config.Runtime.totalRounds, numEnodeBs, 1:Config.MacroEnb.numPRBs) = struct('UeId', NaN, 'MCS', NaN, 'ModOrd', NaN);
			obj.schedule = temp;
			if Config.Harq.active
				obj.harqRtx = zeros(Config.Runtime.totalRounds, numEnodeBs);
				obj.arqRtx = zeros(Config.Runtime.totalRounds, numEnodeBs);
			end
			obj.powerState = zeros(Config.Runtime.totalRounds, numEnodeBs);
			
			% Initialise for UE
			obj.ber = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.snrdB = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.sinrdB = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.estsinrdB = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.bler = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.cqi = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.preEvm = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.postEvm = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.throughput = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.receivedPowerdBm = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.rsrpdBm = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.rssidBm = zeros(Config.Runtime.totalRounds, Config.Ue.number);
			obj.rsrqdB = zeros(Config.Runtime.totalRounds, Config.Ue.number);
		end
		
		% eNodeB metrics
		function obj = recordEnbMetrics(obj, Cells, Config, Logger)
			% Increment the scheduling round for Matlab's indexing
			schRound = Config.Runtime.currentRound + 1;
			obj = obj.recordUtil(Cells, schRound);
			obj = obj.recordPower(Cells, schRound, Config.Son.powerScale, Config.Son.utilLow, Logger);
			obj = obj.recordSchedule(Cells, schRound);
			obj = obj.recordPowerState(Cells, schRound);
			if Config.Harq.active
				obj = obj.recordHarqRtx(Cells, schRound);
				obj = obj.recordArqRtx(Cells, schRound);
			end
		end
		
		function obj = recordUtil(obj, Cells, schRound)
			for iCell = 1:length(Cells)
				sch = find([Cells(iCell).Schedulers.downlink.PRBsActive.UeId] ~= -1);
				utilPercent = 100*find(sch, 1, 'last' )/length(Cells(iCell).Schedulers.downlink.PRBsActive);
				
				% check utilPercent and change to 0 if null
				if isempty(utilPercent)
					utilPercent = 0;
				end
				
				obj.util(schRound, iCell) = utilPercent;
			end
		end
		
		function obj = recordPower(obj, Cells, schRound, otaPowerScale, utilLo, Logger)
			for iCell = 1:length(Cells)
				if ~isempty(obj.util(schRound, iCell))
					Cells(iCell) = Cells(iCell).calculatePowerIn(obj.util(schRound, iCell)/100, otaPowerScale, utilLo);
					obj.powerConsumed(schRound, iCell) = Cells(iCell).PowerIn;
				else
					Logger.log('(METRICS RECORDER - recordPower) metric cannot be recorded. Please call recordUtil first.','ERR')
				end
			end
		end
		
		function obj = recordSchedule(obj, Cells, schRound)
			for iCell = 1:length(Cells)
				numPrbs = length(Cells(iCell).Schedulers.downlink.PRBsActive);
				obj.schedule(schRound, iCell, 1:numPrbs) = Cells(iCell).Schedulers.downlink.PRBsActive;
			end
		end
		
		function obj = recordHarqRtx(obj, Cells, schRound)
			for iCell = 1:length(Cells)
				harqProcs = [Cells(iCell).Mac.HarqTxProcesses.processes];
				obj.harqRtx(schRound, iCell) = sum([harqProcs.rtxCount]);
			end
		end
		
		function obj = recordArqRtx(obj, Cells, schRound)
			for iCell = 1:length(Cells)
				arqProcs = [Cells(iCell).Rlc.ArqTxBuffers.tbBuffer];
				obj.arqRtx(schRound, iCell) = sum([arqProcs.rtxCount]);
			end
		end
		
		function obj = recordPowerState(obj, Cells, schRound)
			for iCell = 1:length(Cells)
				obj.powerState(schRound, iCell) = Cells(iCell).PowerState;
			end
		end
		
		% UE metrics
		function obj = recordUeMetrics(obj, Users, schRound, Logger)
			% Increment the scheduling round for Matlab's indexing
			schRound = schRound + 1;
			obj = obj.recordBer(Users, schRound);
			obj = obj.recordBler(Users, schRound);
			obj = obj.recordSnrdB(Users, schRound);
			obj = obj.recordSinrdB(Users, schRound);
			obj = obj.recordCqi(Users, schRound);
			obj = obj.recordEvm(Users, schRound);
			obj = obj.recordThroughput(Users, schRound);
			obj = obj.recordReceivedPowerdBm(Users, schRound);
			obj = obj.recordRSMeasurements(Users,schRound);
		end
		
		function obj = recordBer(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.Bits) && Users(iUser).Rx.Bits.tot ~= 0
					obj.ber(schRound, iUser) = Users(iUser).Rx.Bits.err/Users(iUser).Rx.Bits.tot;
				else
					obj.ber(schRound, iUser) = NaN;
				end
			end
		end
		
		function obj = recordBler(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.Blocks) && Users(iUser).Rx.Blocks.tot ~= 0
					obj.bler(schRound, iUser) = Users(iUser).Rx.Blocks.err/Users(iUser).Rx.Blocks.tot;
				else
					obj.bler(schRound, iUser) = NaN;
				end
			end
		end
		
		function obj = recordRSMeasurements(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.RSSIdBm)
					obj.rssidBm(schRound, iUser) = Users(iUser).Rx.RSSIdBm;
				end
				if ~isempty(Users(iUser).Rx.RSRPdBm)
					obj.rsrpdBm(schRound, iUser) = Users(iUser).Rx.RSRPdBm;
				end
				if ~isempty(Users(iUser).Rx.RSRQdB)
					obj.rsrqdB(schRound, iUser) = Users(iUser).Rx.RSRQdB;
				end
			end
		end
		
		function obj = recordSnrdB(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(fieldnames(Users(iUser).Rx.ChannelConditions))
					obj.snrdB(schRound, iUser) = Users(iUser).Rx.ChannelConditions.SNRdB;
				end
			end
		end
		
		function obj = recordSinrdB(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(Users(iUser).Rx.SINRS)
					obj.estsinrdB(schRound, iUser) = Users(iUser).Rx.SINRS;
				end
				if ~isempty(fieldnames(Users(iUser).Rx.ChannelConditions))
					obj.sinrdB(schRound, iUser) = Users(iUser).Rx.ChannelConditions.SINRdB;
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
				if ~isempty(Users(iUser).Rx.Bits) && Users(iUser).Rx.Bits.tot ~= 0
					obj.throughput(schRound, iUser) = Users(iUser).Rx.Bits.ok*10e3;
				else
					obj.throughput(schRound, iUser) = NaN;
				end
			end
		end
		
		function obj = recordReceivedPowerdBm(obj, Users, schRound)
			for iUser = 1:length(Users)
				if ~isempty(fieldnames(Users(iUser).Rx.ChannelConditions))
					obj.receivedPowerdBm(schRound, iUser) = Users(iUser).Rx.ChannelConditions.RxPwdBm;
				end
			end
		end
		
		
	end
end