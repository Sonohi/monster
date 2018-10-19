classdef MonsterConfig < handle
	% This class provides a support utility for the simulation configuration
	% During simulation runtime, the modules access the sim config via an object of this class
	% A MonsterConfig object is constituted by:
	% 
	% :simulationLength the total length of the simulation

	properties 
		% Properties related to simulation runtime
		simulationLength;
		currentSimulationRound;
		currentSimulationTime;
		runtimePlot;
		generateCoverageMap;

		% Properties related to the configuration of eNodeBs
		macroENodeB = struct('number': 1, 'subframes': 50, 'height': 35, 'positioning': 'centre',...
			'noiseFigure': 7, 'antennaGain': 0);
		microENodeB = struct('number': 1, 'subframes': 25, 'height': 25, 'positioning': 'hexagonal',...
			'radius': 200, 'noiseFigure', 7, 'antennaGain', 0);
		picoENodeB = struct('number': 1, 'subframes': 6, 'height': 5, 'positioning': 'uniform', ...
			'radius': 200, 'noiseFigure', 7, 'antennaGain', 0);

		% Properties related to the configuration of UEs
		ue = struct('number': 1, 'subframes': 25, 'height': 1.5);

		% Properties related to mobility
		mobility = struct('scenario': 'pedestrian', 'step': 0.01);

		% Properties related to handover
		handover = struct('x2Timer': 0.01);

		% Properties related to terrain and scenario 
		buildings = struct('file', 'mobility/buildings.txt', 'heightRange': [20,50])

		% Properties related to the traffic
		traffic = struct('primary': 'webBrowsing', 'secondary': 'videoStreaming', 'mix': 0.5,... 
			'arrivalDistribution': 'Poisson', 'poissonLambda': 5, 'uniformRange': [6, 10], 'static': 0 );

		% Properties related to the physical layer
		phy = struct('uplinkFrequency', 1747.5, 'downlinkFrequency', 1842.5,...
			'pucchFormat', 2, 'prachInterval', 10, 'prbSymbols', 160, 'prbResourceElements', 168, ...
			'maxTbSize', 97896, 'maxCwdSize', 10e5);

		% Properties related to the channel
		channel = struct('uplinkMode': 'B2B', 'downlinkMode': '3GPP38901', 'fadingActive': true,...
			'interferenceActive': true, 'shadowingActive': true, 'losMethod': '3GPP38901-probability', ...
			'region': struct('type': 'Urban', 'macroScenario', 'UMa', 'microScenario': 'UMi', 'picoScenario', 'UMi'))

		% Properties related to scheduling
		scheduling = struct('type': 'roundRobin', 'refreshAssociationTimer': 0.01, 'icScheme', 'none', ...
			'absMask', [1,0,1,0,0,0,0,0,0,0]);

		% Properties related to SON and power saving
		son = struct('neighbourRadius', 100, 'hysteresisTimer', 0.001, 'switchTimer', 0.001, ...
			'utilisationRange', [1,100], 'powerScale', 1);

		% Properties related to HARQ
		harq = struct('active', true, 'maxRetransmissions', 3, 'redundacyVersion', [1, 3, 2], ...
			'processes', 8, 'timeout': 3);

		% Properties related to ARQ
		arq = struct('active', true, 'maxRetransmissions', 1, 'maxBufferSize', 1024, 'timer', 20);

	end

	methods
		function obj = MonsterConfig(Param)
			% The constructor replaces the default values of the class with those in the Param structure
			
		end


		
	end
en