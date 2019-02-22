classdef MonsterConfig < matlab.mixin.Copyable
	% This class provides a support utility for the simulation configuration
	% During simulation runtime, the modules access the sim config via an object of this class
	% An instance of the class MonsterConfig has the following properties:
	% 
	% :Runtime: (struct) configuration for the simulation runtime
	% :Logs: (struct)
	% :SimulationPlot: (struct) configuration for plotting
	% :MacroEnb: (struct) configuration for macro eNodeBs
	% :MicroEnb: (struct) configuration for micro eNodeBs
	% :PicoEnb: (struct) configuration for pico eNodeBs
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
		Runtime = struct();
		Logs = struct();
		SimulationPlot = struct();
		MacroEnb = struct();
		MicroEnb = struct();
		PicoEnb = struct();
		Ue = struct();
		Mobility = struct();
		Handover = struct();
		Terrain = struct();
		Traffic = struct();
		Phy = struct();
		Channel = struct();
		Scheduling = struct();
		Son = struct();
		Harq = struct();
		Arq = struct();
		Plot = struct();
	end

	methods
		function obj = MonsterConfig()
			% MonsterConfig constructor sets the simulation configuration
			% 
			% MonsterConfig instance
			%

			% Parameters related to simulation run time
			Runtime = struct();
			numRounds = 100;
			Runtime.totalRounds = numRounds;
			Runtime.remainingRounds = numRounds;
			Runtime.currentRound = 0;
			Runtime.currentTime = 0;
			Runtime.remainingTime = Runtime.totalRounds*10e-3;
			Runtime.realTimeElaspsed = 0;
			Runtime.realTimeRemaining = numRounds * 10;
			Runtime.seed = 126;
			obj.Runtime = Runtime;

			% Logs configuration
			Logs = struct();
			Logs.logToFile = 0;
			Logs.dateFormat = 'yyyy-mm-dd_HH.MM.SS';
			Logs.logLevel = 'NFO';
			Logs.logPath = 'logs/';
			Logs.defaultLogName = strcat(Logs.logPath, datestr(datetime, Logs.dateFormat));
			obj.Logs = Logs;

			% Properties related to drawing and plotting
			SimulationPlot = struct();
			SimulationPlot.runtimePlot = 0;
			SimulationPlot.generateCoverageMap = 0;
			SimulationPlot.generateHeatMap = 0;
			SimulationPlot.heatMapType = 'perStation';
			SimulationPlot.heatMapRes = 10;
			obj.SimulationPlot = SimulationPlot;

			% Properties related to the configuration of eNodeBs
			MacroEnb = struct();
			MacroEnb.number = 1;
			MacroEnb.subframes = 50;
			MacroEnb.height = 35;
			MacroEnb.positioning = 'centre';
			MacroEnb.radius = 1000;
			MacroEnb.noiseFigure = 7;
			MacroEnb.antennaGain = 0;
			MacroEnb.antennaType = 'omni';
			obj.MacroEnb = MacroEnb;

			MicroEnb = struct();
			MicroEnb.number = 0;
			MicroEnb.subframes = 25;
			MicroEnb.height = 25;
			MicroEnb.positioning = 'hexagonal';
			MicroEnb.radius = 200;
			MicroEnb.noiseFigure = 7;
			MicroEnb.antennaGain = 0;
			MicroEnb.antennaType = 'omni';
			obj.MicroEnb = MicroEnb;

			PicoEnb = struct();
			PicoEnb.number = 0;
			PicoEnb.subframes = 6;
			PicoEnb.height = 5;
			PicoEnb.positioning = 'uniform';
			PicoEnb.radius = 200;
			PicoEnb.noiseFigure = 7;
			PicoEnb.antennaGain = 0;
			PicoEnb.antennaType = 'omni';
			obj.PicoEnb = PicoEnb;

			% Properties related to the configuration of UEs
			Ue = struct();
			Ue.number = 1;
			Ue.subframes = 25;
			Ue.height = 1.5;
			Ue.noiseFigure = 7;
			Ue.antennaGain = 0;
			Ue.antennaType = 'omni';
			obj.Ue = Ue;

			% Properties related to mobility
			Mobility = struct();
			Mobility.scenario = 'pedestrian';
			Mobility.step = 0.01;
			Mobility.seed = 19;
			obj.Mobility = Mobility;

			% Properties related to handover
			Handover = struct();
			Handover.x2Timer = 0.01;
			obj.Handover = Handover;

			% Properties related to terrain and scenario 
			Terrain = struct();
			Terrain.buildingsFile = 'mobility/buildings.txt';
			Terrain.heightRange = [20,50];
			Terrain.buildings = load(Terrain.buildingsFile);
			Terrain.buildings(:,5) = randi([Terrain.heightRange],[1 length(Terrain.buildings(:,1))]);
			Terrain.area = [...
				min(Terrain.buildings(:, 1)), ...
				min(Terrain.buildings(:, 2)), ...
				max(Terrain.buildings(:, 3)), ...
				max(Terrain.buildings(:, 4))];
			obj.Terrain = Terrain;

			% Properties related to the traffic
			Traffic = struct();
			Traffic.primary = 'videoStreaming';
			Traffic.secondary = 'videoStreaming';
			Traffic.mix = 0.5;
			Traffic.arrivalDistribution = 'Poisson';
			Traffic.poissonLambda = 5;
			Traffic.uniformRange = [6, 10];
			Traffic.static = 0; 
			obj.Traffic = Traffic;

			% Properties related to the physical layer
			Phy = struct();
			Phy.uplinkFrequency = 1747.5;
			Phy.downlinkFrequency = 1842.5;
			Phy.pucchFormat = 2;
			Phy.prachInterval = 10;
			Phy.prbSymbols = 160;
			Phy.prbResourceElements = 168;
			Phy.maxTbSize = 97896;
			Phy.maxCwdSize = 10e5;
			Phy.mcsTable = [0,1,3,4,6,7,9,11,13,15,20,21,22,24,26,28]';
			Phy.modOrdTable = [2,2,2,2,2,2,4,4,4,6,6,6,6,6,6];
			obj.Phy = Phy;

			% Properties related to the channel
			Channel = struct();
			Channel.mode = '3GPP38901';
			Channel.fadingActive = false;
			Channel.interferenceType = 'Full';
			Channel.shadowingActive = false;
			Channel.reciprocityActive = true;
			Channel.perfectSynchronization = true;
			Channel.losMethod = '3GPP38901-probability';
			Channel.region = struct('type', 'Urban', 'macroScenario', 'UMa', 'microScenario', 'UMi', 'picoScenario', 'UMi');
			obj.Channel = Channel;

			% Properties related to scheduling
			Scheduling = struct();
			Scheduling.type = 'roundRobin';
			Scheduling.refreshAssociationTimer = 0.01;
			Scheduling.icScheme = 'none';
			Scheduling.absMask = [1,0,1,0,0,0,0,0,0,0];
			obj.Scheduling = Scheduling;

			% Properties related to SON and power saving
			Son = struct();
			Son.neighbourRadius = 100;
			Son.hysteresisTimer = 0.001;
			Son.switchTimer = 0.001;
			Son.utilisationRange = 1:100;
			Son.utilLow = Son.utilisationRange(1);
			Son.utilHigh = Son.utilisationRange(end);
			Son.powerScale = 1;
			obj.Son = Son;

			% Properties related to HARQ
			Harq = struct();
			Harq.active = true;
			Harq.maxRetransmissions = 3;
			Harq.redundacyVersion = [1, 3, 2];
			Harq.processes = 8;
			Harq.timeout = 3;
			obj.Harq = Harq;

			% Properties related to ARQ
			Arq = struct();
			Arq.active = true;
			Arq.maxRetransmissions = 1;
			Arq.maxBufferSize = 1024;
			Arq.timeout = 20;
			obj.Arq = Arq;

			% Properties related to plotting
			Plot = struct();
			if obj.SimulationPlot.runtimePlot
				Plot.Layout = '';
				Plot.LayoutFigure = '';
				Plot.LayoutAxes = axes;
				Plot.PHYFigure = '';
				Plot.PHYAxes = axes;
			end
			obj.Plot = Plot;

			% Check the number of macros and throw an error if set to an unsupported number
			%assert(obj.MacroEnb.number == 1, '(MONSTER CONFIG - constructor) only 1 macro eNodeB currently supported');
			% Check traffic configuration
			assert(obj.Traffic.mix >= 0, '(SETUP - setupTraffic) error, traffic mix cannot be negative');

			% Plot
			if SimulationPlot.runtimePlot
				[obj.Plot.LayoutFigure, obj.Plot.LayoutAxes] = createLayoutPlot(obj);
				[obj.Plot.PHYFigure, obj.Plot.PHYAxes] = createPHYplot(obj);
			end

		end

		function setupNetworkLayout(obj)
				% Setup the layout given the config
				%
				% Syntax: Config.setupNetworkLayout()
				% Parameters:
				% :obj: (MonsterConfig) simulation config class instance
				%	Sets:
				% :obj.Plot.Layout: (<NetworkLayout>) network layout class instance
			xc = (obj.Terrain.area(3) - obj.Terrain.area(1))/2;
			yc = (obj.Terrain.area(4) - obj.Terrain.area(2))/2;
			obj.Plot.Layout = NetworkLayout(xc,yc,obj); 
		end

		function storeConfig(obj, logName)
			% storeConfig is used to log the configuration used for a simulation
			%
			% :obj: the MonsterConfig instance
			% :logName: the name of the log to use, minus path and date
			
			fullLogName = strcat(obj.Logs.defaultLogName, logName);
			save(fullLogName, 'obj')
		end
		
	end
end