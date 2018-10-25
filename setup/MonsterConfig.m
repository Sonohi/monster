classdef MonsterConfig < handle
	% This class provides a support utility for the simulation configuration
	% During simulation runtime, the modules access the sim config via an object of this class
	% An instance of the class MonsterConfig has the following properties:
	% 
	% :Runtime: (struct) configuration for the simulation runtime
	% :SimulationPlot: (struct) configuration for plotting
	% :MacroENodeB: (struct) configuration for macro eNodeBs
	% :MicroENodeB: (struct) configuration for micro eNodeBs
	% :PicoENodeB: (struct) configuration for pico eNodeBs
	%	:Ue: (struct) configuration for UEs
	% :Mobility: (struct) configuration for UE mobility
	% :Handover: (struct) configuration for X2 and S1 handover
	% :Terrain: (struct) configuration for terrain and buildings
	% :Traffic: (struct) configuration for traffic models and UE arrival distributions
	% :Phy: (struct) configuration for physical layer parameters (e.g. LTE channel formats, frequencies, etc.)
	% :Channel: (struct) configuration for uplink and downlink channel models
	% :Scheduling: (struct) configuration for the eNodeB downlink schedulink algorithm
	% :Son: (struct) configuration for SON-related parameters
	% :Harq: (struct) configuration for the HARQ protocol (e.g. activation, etc.)
 	% :Arq: (struct) configuration for the ARQ protocol (e.g activation, etc.)

	properties 
		% Parameters related to simulation run time
		Runtime = struct('totalRounds', 1000, 'simTimeElapsed', 0, 'simTimeRemaining', 1, ...
			'realTimeElaspsed', 0, 'realTimeRemaining', 1000, 'currentRound', 0, 'currentTime', 0)

		% Properties related to drawing and plotting
		SimulationPlot = struct('runtimePlot', 0, 'generateCoverageMap', 0, 'generateHeatMap', 0, ...
			'heatMapType', 'perStation', 'heatMapRes', 10);

		% Properties related to the configuration of eNodeBs
		MacroENodeB = struct('number': 1, 'subframes': 50, 'height': 35, 'positioning': 'centre',...
			'noiseFigure': 7, 'antennaGain': 0);
		MicroENodeB = struct('number': 1, 'subframes': 25, 'height': 25, 'positioning': 'hexagonal',...
			'radius': 200, 'noiseFigure', 7, 'antennaGain', 0);
		PicoENodeB = struct('number': 1, 'subframes': 6, 'height': 5, 'positioning': 'uniform', ...
			'radius': 200, 'noiseFigure', 7, 'antennaGain', 0);

		% Properties related to the configuration of UEs
		Ue = struct('number': 1, 'subframes': 25, 'height': 1.5, 'noiseFigure': 7, 'antennaGain': 0);

		% Properties related to mobility
		Mobility = struct('scenario': 'pedestrian', 'step': 0.01);

		% Properties related to handover
		Handover = struct('x2Timer': 0.01);

		% Properties related to terrain and scenario 
		Terrain = struct('buildingsFile', 'mobility/buildings.txt', 'heightRange': [20,50], ...
			'buildings', [],'area': []);

		% Properties related to the traffic
		Traffic = struct('primary': 'webBrowsing', 'secondary': 'videoStreaming', 'mix': 0.5,... 
			'arrivalDistribution': 'Poisson', 'poissonLambda': 5, 'uniformRange': [6, 10], 'static': 0 );

		% Properties related to the physical layer
		Phy = struct('uplinkFrequency', 1747.5, 'downlinkFrequency', 1842.5,...
			'pucchFormat', 2, 'prachInterval', 10, 'prbSymbols', 160, 'prbResourceElements', 168, ...
			'maxTbSize', 97896, 'maxCwdSize', 10e5);

		% Properties related to the channel
		Channel = struct('uplinkMode': 'B2B', 'downlinkMode': '3GPP38901', 'fadingActive': true,...
			'interferenceActive': true, 'shadowingActive': true, 'losMethod': '3GPP38901-probability', ...
			'region': struct('type': 'Urban', 'macroScenario', 'UMa', 'microScenario': 'UMi', 'picoScenario', 'UMi'));

		% Properties related to scheduling
		Scheduling = struct('type': 'roundRobin', 'refreshAssociationTimer': 0.01, 'icScheme', 'none', ...
			'absMask', [1,0,1,0,0,0,0,0,0,0]);

		% Properties related to SON and power saving
		Son = struct('neighbourRadius', 100, 'hysteresisTimer', 0.001, 'switchTimer', 0.001, ...
			'utilisationRange', [1,100], 'powerScale', 1);

		% Properties related to HARQ
		Harq = struct('active', true, 'maxRetransmissions', 3, 'redundacyVersion', [1, 3, 2], ...
			'processes', 8, 'timeout': 3);

		% Properties related to ARQ
		Arq = struct('active', true, 'maxRetransmissions', 1, 'maxBufferSize', 1024, 'timeout', 20);

	end

	methods
		function obj = MonsterConfig(Param)
			% The constructor replaces the default values of the class with those in the Param structure
			% Runtime
			obj.Runtime.totalRounds = Param.schRounds;
			obj.Runtime.simTimeRemaining = Param.schRounds/1000;
			
			% Simulation plotting
			obj.SimulationPlot.runtimePlot = Param.draw;
			obj.SimulationPlot.generateCoverageMap = Param.channel.computeCoverage;
			obj.SimulationPlot.generateHeatMap = Param.generateHeatMap;
			obj.SimulationPlot.heatMapType = Param.heatMapType;
			obj.SimulationPlot.heatMapRes = Param.heatMapRes;

			% Macro eNodeBs
			obj.MacroENodeB.number = Param.numMacro;
			obj.MacroENodeB.subframes = Param.numSubFramesMacro;
			obj.MacroENodeB.height = Param.macroHeight;
			obj.MacroENodeB.noiseFigure = Param.eNBNoiseFigure;
			obj.MacroENodeB.antennaGain = Param.eNBGain;

			% Micro eNodeBs
			obj.MicroENodeB.number = Param.numMicro;
			obj.MicroENodeB.subframes = Param.numSubFramesMicro;
			obj.MicroENodeB.height = Param.microHeight;
			obj.MicroENodeB.noiseFigure = Param.eNBNoiseFigure;
			obj.MicroENodeB.antennaGain = Param.eNBGain;
			obj.MicroENodeB.positioning = Param.microPos;
			obj.MicroENodeB.radius = Param.microUniformRadius;

			% Pico eNodeBs
			obj.PicoENodeB.number = Param.numPico;
			obj.PicoENodeB.subframes = Param.numSubFramesPico;
			obj.PicoENodeB.height = Param.picoHeight;
			obj.PicoENodeB.noiseFigure = Param.eNBNoiseFigure;
			obj.PicoENodeB.antennaGain = Param.eNBGain;
			obj.PicoENodeB.positioning = Param.picoPos;
			obj.PicoENodeB.radius = Param.picoUniformRadius;
			
			% UEs
			obj.Ue.number = Param.numUsers;
			obj.Ue.subframes = Param.numSubFramesUE;
			obj.Ue.height = Param.ueHeight;
			obj.Ue.noiseFigure = Param.ueNoiseFigure;
			obj.Ue.antennaGain = Param.ueGain;

			% Mobility
			obj.Mobility.scenario = Param.mobilityScenario;
			obj.Mobility.step = Param.mobilityStep;

			% Handover
			obj.Handover.x2Timer = Param.handoverTimer;

			% Terrain
			obj.Terrain.buildingsFile = Param.buildings;
			obj.Terrain.heightRange = Param.buildingHeight;
			obj.Terrain.buildings = load(obj.Terrain.buildingsFile);
			obj.Terrain.buildings(:,5) = randi([obj.Terrain.heightRange],[1 length(obj.Terrain.buildings(:,1))]);
			obj.Terrain.area = [...
				min(obj.Terrain.buildings(:, 1)), ...
				min(obj.Terrain.buildings(:, 2)), ...
				max(obj.Terrain.buildings(:, 3)), ...
				max(obj.Terrain.buildings(:, 4))];
			
			% Traffic
			obj.Traffic.primary = Param.primaryTrafficModel;
			obj.Traffic.secondary = Param.secondaryTrafficModel;
			obj.Traffic.mix = Param.trafficMix;
			obj.Traffic.arrivalDistribution = Param.ueArrivalDistribution;
			obj.Traffic.poissonLambda = Param.poissonLambda;
			obj.Traffic.uniformRange = [Param.uniformLower, Param.uniformUpper];
			obj.Traffic.static = Param.staticStart;

			% Phy
			obj.Phy.uplinkFrequency = Param.ulFreq;
			obj.Phy.downlinkFrequency = Param.dlFreq;
			obj.Phy.pucchFormat = Param.pucchFormat;
			obj.Phy.prachInterval = Param.PRACHInterval;
			obj.Phy.prbSymbols = Param.prbSym;
			obj.Phy.prbResourceElements = Param.prbRe;
			obj.Phy.maxTbSize = Param.maxTbSize;
			obj.Phy.maxCwdSize = Param.maxCwdSize;

			% Channel
			obj.Channel.uplinkMode = Param.channel.modeUL;
			obj.Channel.downlinkMode = Param.channel.modeDL;
			obj.Channel.fadingActive = Param.channel.enableFading;
			obj.Channel.interferenceActive = Param.channel.enableInterference;
			obj.Channel.shadowingActive = Param.channel.enableShadowing;
			obj.Channel.losMethod = Param.channel.LOSMethod;
			obj.Channel.region.type = Param.channel.region;
			obj.Channel.region.macroScenario = Param.channel.region.macroScenario;
			obj.Channel.region.microScenario = Param.channel.region.microScenario;
			obj.Channel.region.picoScenario = Param.channel.region.picoScenario;
			
			% Scheduling
			obj.Scheduling.type = Param.scheduling;
			obj.Scheduling.refreshAssociationTimer = Param.refreshAssociationTimer;
			obj.Scheduling.icScheme = Param.icScheme;
			obj.Scheduling.absMask = Param.absMask;

			% SON
			obj.Son.neighbourRadius = Param.nboRadius;
			obj.Son.hysteresisTimer = Param.tHyst;
			obj.Son.switchTimer = Param.tSwitch;
			obj.Son.utilisationRange = [Param.utilLoThr, Param.utilHiThr];
			obj.Son.powerScale = Param.otaPowerScale;
			
			% HARQ 
			obj.Harq.active = Param.rtxOn;
			obj.Harq.maxRetransmissions = Param.harq.rtxMax;
			obj.Harq.redundacyVersion = Param.harq.rv;
			obj.Harq.processes = Param.harq.proc;
			obj.Harq.timeout = Param.harq.tout;

			% ARQ
			obj.Arq.active = Param.rtxOn;
			obj.Arq.maxRetransmissions = Param.arq.rtxMax;
			obj.Arq.maxBufferSize = Param.arq.maxBufferSize;
			obj.Arq.timeout = Param.arq.bufferFlusTimer;			

		end




		
	end
en