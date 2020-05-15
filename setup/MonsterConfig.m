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
	% :Mimo: (struct) configuration for the global transmission mode for the simulation

	properties 
		Runtime = struct();
		Logs = struct();
		SimulationPlot = struct();
		MacroEnb = struct();
		MicroEnb = struct();
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
		Scenario = struct();
		Backhaul = struct();
		SRS = struct();
		Mimo = struct();
	end

	methods
		function obj = MonsterConfig()
			% MonsterConfig constructor sets the simulation configuration
			% 
			% MonsterConfig instance
			%

			% Parameters related to simulation run time
			Runtime = struct();
			Runtime.simulationRounds = 10;
			Runtime.seed = 126;
			Runtime.mode = 'default'; % default | app depending on code execution
			obj.Runtime = Runtime;

			% Logs configuration
			Logs = struct();
			Logs.logToFile = 0; % 0 only console | 1 only file | 2 both 
			Logs.logInBlack = 0;
			Logs.dateFormat = 'yyyy-mm-dd_HH.MM.SS';
			Logs.logLevel = 'NFO';
			Logs.logPath = 'logs/';
			Logs.logFile = strcat(Logs.logPath, datestr(datetime, Logs.dateFormat), '.log');
			Logs.logCount = 100; 
			obj.Logs = Logs;

			% Properties related to drawing and plotting
			SimulationPlot = struct();
			SimulationPlot.runtimePlot = 1;
			obj.SimulationPlot = SimulationPlot;

			% Properties related to the configuration of eNodeBs
			MacroEnb = struct();
			MacroEnb.sitesNumber = 1;
			MacroEnb.cellsPerSite = 3;
			MacroEnb.numPRBs = 50; %50 corresponds to a bandwidth of 10MHz
			MacroEnb.height = 35;
			MacroEnb.positioning = 'centre';
			MacroEnb.ISD = 500;
			MacroEnb.noiseFigure = 0;
			MacroEnb.antennaGain = 0;
			MacroEnb.antennaType = 'sectorised';
			MacroEnb.Pmax = 20; % W
			obj.MacroEnb = MacroEnb;

			MicroEnb = struct();
			MicroEnb.sitesNumber = 3;
			MicroEnb.cellsPerSite = 1;
			MicroEnb.microPosPerMacroCell = 3; % standard from ITU-RM2412-0 scenario 8.3.2
			MicroEnb.numPRBs = 25;
			MicroEnb.height = 25;
			MicroEnb.positioning = 'hexagonal';
			MicroEnb.ISD = 100;
			MicroEnb.noiseFigure = 7;
			MicroEnb.antennaGain = 0;
			MicroEnb.antennaType = 'omni';
			MicroEnb.Pmax = 6.3;
			obj.MicroEnb = MicroEnb;

			% Properties related to the configuration of UEs
			Ue = struct();
			Ue.number = 10;
			Ue.numPRBs = 25;
			Ue.height = 1.5;
			Ue.noiseFigure = 9;
			Ue.antennaGain = 0;
			Ue.antennaType = 'omni'; % omni | vivaldi
			obj.Ue = Ue;

			% Properties related to mobility
			Mobility = struct();
			Mobility.scenario = 'pedestrian'; % pedestrian | pedestrian-indoor | maritime
			Mobility.step = 0.01;
			Mobility.seed = 19;
			obj.Mobility = Mobility;

			% Properties related to handover
			Handover = struct();
			Handover.x2Timer = 0.01;
			obj.Handover = Handover;

			% Properties related to terrain and scenario, based on the terrain type
			Terrain = struct();
			Terrain.type = 'geo'; % geo | manhattan | maritime
			Terrain.roadsFile = 'layout/dk_2800_dtu_campus_roads.shp';
			Terrain.averageElevation = 33; % in m
			obj.Terrain = Terrain;

			% Properties related to backhaul
			Backhaul = struct();
			Backhaul.backhaulOn = 1;
			Backhaul.propagationSpeed = 2*10^8; % [m/s] (usual speed of light in a fiber optic cable is approx. 2*10^8 m/s)
			Backhaul.lengthOfMedium = 1000; % [m]
			Backhaul.bandwidth = 10^9; % [bps] 
			Backhaul.utilizationLimit = 0.8; %A value of 1 gives 100% of the medium can be used for dataplane traffic.
			Backhaul.switchDelay = 10^(-4); %[ms]
			Backhaul.errorRate = 0.1; %fraction of errors
			Backhaul.errorMagnitude = 0.5; %Magnitude of error, e.g. 0.5 deletes half the packet when the error occurs
			obj.Backhaul = Backhaul;

			% Properties related to the traffic 
			% Traffic types: fullBuffer | videoStreaming | webBrowsing 
			Traffic = struct();
			Traffic.primary = 'fullBuffer';
			Traffic.secondary = 'videoStreaming';
			Traffic.mix = 0;
			Traffic.arrivalDistribution = 'Static'; % Static | Uniform | Poisson
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
			obj.Phy = Phy;

			% Properties related to the channel
			Channel = struct();
			Channel.mode = '3GPP38901';
			Channel.fadingActive = true;
			Channel.fadingModel = 'TDL'; % TDL | CDL
			Channel.interferenceType = 'Power'; % 'Power', 'Frequency' 
			Channel.shadowingActive = true;
			Channel.reciprocityActive = true;
			Channel.perfectSynchronization = true;
			Channel.losMethod = '3GPP38901-probability'; % 'NLOS', '3GPP38901-probability', 'LOS'
			Channel.region = struct('type', 'Urban', 'macroScenario', 'UMa', 'microScenario', 'UMi', 'picoScenario', 'UMi');
			obj.Channel = Channel;

			% Properties related to scheduling
			Scheduling = struct();
			Scheduling.type = 'roundRobin';
			Scheduling.refreshAssociationTimer = 0.01;
			Scheduling.icScheme = 'none';
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
			
			% Properties related to SRS
			SRS = struct();
			SRS.active = true;
			obj.SRS = SRS;

			% Properties related to MIMO configuration
			Mimo = struct();
			Mimo.transmissionMode = "Port0"; % Supported Port0 | TxDiversity
			Mimo.elementsPerPanel = [1, 1]; % panel configuration MxN as per 3GPP 38.901 
			obj.Mimo = Mimo;
		end

		function assertConfig(obj)
			% Asserts the configuration of the simulation 
			%
			% :param obj: MonsterConfig instance including scenario-specific configurations
			%

			% Assert macro eNodeB configuration
			if strcmp(obj.MacroEnb.antennaType, 'sectorised')
				errMsg = "(CONFIG - assertConfig) invalid value for MacroEnb.cellsPerSite with sectorised antenna type. Only 1 and 3 sectors are allowed";
				assert(obj.MacroEnb.cellsPerSite == 1 || obj.MacroEnb.cellsPerSite == 3, errMsg)
			end

			% Assert micro eNodeB configuration
			if strcmp(obj.MicroEnb.antennaType, 'sectorised')
				errMsg = "(CONFIG - assertConfig) invalid value for MicroEnb.cellsPerSite with sectorised antenna type. Only 1 and 3 sectors are allowed";
				assert(obj.MicroEnb.cellsPerSite == 1 || obj.MicroEnb.cellsPerSite == 3, errMsg)
			end

			errMsg = "(CONFIG - assertConfig) invalid value for Phy.pucchFormat. Only 2 is currently implemented";
			assert(obj.Phy.pucchFormat == 2, errMsg);
			errMsg = "(CONFIG - assertConfig) invalid value for Traffic.Mix. Only non negative values are allowed.";
			assert(obj.Traffic.mix >= 0, errMsg);
		end

		function storeConfig(obj, logName)
			% storeConfig is used to log the configuration used for a simulation
			%
			% :obj: the MonsterConfig instance
			% :logName: the name of the log to use, minus path and date
			
			fullLogName = strcat(obj.Logs.logFile, logName);
			save(fullLogName, 'obj')
		end
		
	end
end