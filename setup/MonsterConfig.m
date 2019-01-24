classdef MonsterConfig < handle
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
		% Parameters related to simulation run time
		Runtime = struct('totalRounds', 1000, 'remainingRounds', 1000, 'currentRound', 0, 'currentTime', 0,...
			'remainingTime', 1, 'realTimeElaspsed', 0, 'realTimeRemaining', 1000,...
			'reInstall', 0, 'seed', 126);
		
		Logs = struct('logToFile', 0, 'dateFormat', 'yyyy-mm-dd_HH.MM.SS', ...
			'logLevel', 'NFO', 'logPath', 'logs/', 'defaultLogName', '');

		% Properties related to drawing and plotting
		SimulationPlot = struct('runtimePlot', 0, 'generateCoverageMap', 0, 'generateHeatMap', 0, ...
			'heatMapType', 'perStation', 'heatMapRes', 10);

		% Properties related to the configuration of eNodeBs
		MacroEnb = struct('number', 1, 'subframes', 50, 'height', 35, 'positioning', 'centre',...
			'noiseFigure', 7, 'antennaGain', 0);
		MicroEnb = struct('number', 1, 'subframes', 25, 'height', 25, 'positioning', 'hexagonal',...
			'radius', 200, 'noiseFigure', 7, 'antennaGain', 0);
		PicoEnb = struct('number', 1, 'subframes', 6, 'height', 5, 'positioning', 'uniform', ...
			'radius', 200, 'noiseFigure', 7, 'antennaGain', 0);

		% Properties related to the configuration of UEs
		Ue = struct('number', 1, 'subframes', 25, 'height', 1.5, 'noiseFigure', 7, 'antennaGain', 0);

		% Properties related to mobility
		Mobility = struct('scenario', 'pedestrian', 'step', 0.01, 'seed', 19);

		% Properties related to handover
		Handover = struct('x2Timer', 0.01);

		% Properties related to terrain and scenario 
		Terrain = struct('buildingsFile', 'mobility/buildings.txt', 'heightRange', [20,50], ...
			'buildings', [],'area', []);

		% Properties related to the traffic
		Traffic = struct('primary', 'webBrowsing', 'secondary', 'videoStreaming', 'mix', 0.5,... 
			'arrivalDistribution', 'Poisson', 'poissonLambda', 5, 'uniformRange', [6, 10], 'static', 0 ); 

		% Properties related to the physical layer
		Phy = struct('uplinkFrequency', 1747.5, 'downlinkFrequency', 1842.5,...
			'pucchFormat', 2, 'prachInterval', 10, 'prbSymbols', 160, 'prbResourceElements', 168, ...
			'maxTbSize', 97896, 'maxCwdSize', 10e5, 'mcsTable', [0,1,3,4,6,7,9,11,13,15,20,21,22,24,26,28]',
			'modOrdTable', [2,2,2,2,2,2,4,4,4,6,6,6,6,6,6]);

		% Properties related to the channel
		Channel = struct('uplinkMode', 'B2B', 'downlinkMode', '3GPP38901', 'fadingActive', true,...
			'interferenceActive', true, 'shadowingActive', true, 'losMethod', '3GPP38901-probability', ...
			'region', struct('type', 'Urban', 'macroScenario', 'UMa', 'microScenario', 'UMi', 'picoScenario', 'UMi'));

		% Properties related to scheduling
		Scheduling = struct('type', 'roundRobin', 'refreshAssociationTimer', 0.01, 'icScheme', 'none', ...
			'absMask', [1,0,1,0,0,0,0,0,0,0]);

		% Properties related to SON and power saving
		Son = struct('neighbourRadius', 100, 'hysteresisTimer', 0.001, 'switchTimer', 0.001, ...
			'utilisationRange', [1,100], 'utilLow', 1, 'utilHigh', 100, 'powerScale', 1);

		% Properties related to HARQ
		Harq = struct('active', true, 'maxRetransmissions', 3, 'redundacyVersion', [1, 3, 2], ...
			'processes', 8, 'timeout', 3);

		% Properties related to ARQ
		Arq = struct('active', true, 'maxRetransmissions', 1, 'maxBufferSize', 1024, 'timeout', 20);

		% Properties related to plotting
		Plot = struct('Layout', '','LayoutFigure','','LayoutAxes', axes, 'PHYFigure', '', 'PHYAxes', axes);

	end

	methods
		function obj = MonsterConfig()
			% MonsterConfig constructor sets some additional runtime parameters
			% 

			% Runtime
			obj.Runtime.remainingTime = obj.Runtime.totalRounds*10e-3;
			
			% Logs
			dateStr = datestr(datetime, obj.Logs.dateFormat);
			obj.Logs.defaultLogName = strcat(obj.Logs.logPath, dateStr);

			% Check the number of macros and throw an error if set to an unsupported number
			assert(obj.MacroEnb.number == 1, '(MONSTER CONFIG - constructor) only 1 macro eNodeB currently supported');

			% Terrain
			obj.Terrain.buildings = load(obj.Terrain.buildingsFile);
			obj.Terrain.buildings(:,5) = randi([obj.Terrain.heightRange],[1 length(obj.Terrain.buildings(:,1))]);
			obj.Terrain.area = [...
				min(obj.Terrain.buildings(:, 1)), ...
				min(obj.Terrain.buildings(:, 2)), ...
				max(obj.Terrain.buildings(:, 3)), ...
				max(obj.Terrain.buildings(:, 4))];
			
			% Traffic
			assert(obj.Traffic.mix >= 0, '(SETUP - setupTraffic) error, traffic mix cannot be negative');

			% SON
			obj.Son.utilLow = obj.Son.utilisationRange(1);
			obj.Son.utilHigh = obj.Son.utilisationRange;			

			% Plot
			xc = (obj.Terrain.area(3) - obj.Terrain.area(1))/2;
			yc = (obj.Terrain.area(4) - obj.Terrain.area(2))/2;
			obj.Plot.Layout = NetworkLayout(xc,yc,obj); 
			if obj.SimulationPlot.runtimePlot
				[obj.Plot.LayoutFigure, obj.Plot.LayoutAxes] = createLayoutPlot(obj);
				[obj.Plot.PHYFigure, obj.Plot.PHYAxes] = createPHYplot(obj);
			end

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