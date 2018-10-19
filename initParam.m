%% SIMULATION PARAMETERS
clear all
Param.reset = 0;% Boolean used to reset the folder structure and reload everything
Param.rmResults = 0;% Boolean to clean the results folder
Param.logToFile = 0; % Boolean, if true all logs are re-directed to a file in /logs

% Boolean used to enable the drawing of plots and other cool stuff
Param.draw = 1;

% Booelan used to store the transmission data, that is each TB, codeword, waveform
Param.storeTxData = 0;

% Integer used to control the number of scheduling rounds (subframes) to simulate
Param.schRounds = 100000;
Param.seed = 42;% Integer used for the simulation seed
Param.mobilitySeed = 19; % Integer for randomizing user positioning and trajectories
% Boolean to save a whole LTE frame for the macro eNodeB for testing
Param.saveFrame = 1;

%% Draw functions
Param.generateHeatMap = 0;% Boolean to control the generation of a heatmap of the pathloos in the scenario
Param.heatMapType = 'perStation';% String to control the type of heatmap
Param.heatMapRes = 10;% Heatmap resoultion in metres

%% Network
Param.numSubFramesMacro = 50;% Integer used to set the number of RBs for a macro eNodeB
Param.numSubFramesMicro = 25;% Integer used to set the number of RBs for a micro eNodeB
Param.numSubFramesPico = 6;% Integer used to set the number of RBs for a pico eNodeB
Param.numSubFramesUE = 25;% Integer used to set the number of RBs for the uplink
Param.numMacro = 1;% Integer used to specify the number of macro eNodeBs in the scenario (currently only 1)
Param.macroHeight = 35;% Double used to specify the height in metres of the macro eNodeBs
Param.numMicro = 9;% Integer used to specify the number of micro eNodeBs in the scenario (currently max 12 if hexagonal is chosen)
Param.microPos = 'hexagonal'; % Array of char to decide the positioning of the micro BS (uniform, random, clusterized, hexagonal)
Param.microUniformRadius = 200;% Double radius of distance from centre for microBS in metres
Param.microHeight = 25;% Double used to specify the height in metres of the micro eNodeBs
Param.numPico = 6;% Integer used to specify the number of pico eNodeBs in the scenario
Param.picoPos = 'uniform'; % Array of char to decide the positioning of the micro BS (uniform, random)
Param.picoUniformRadius = 200;% Double radius of distance from centre for picoBS in metres
Param.picoHeight = 5;% Double used to specify the height in metres of the pico eNodeBs
Param.numEnodeBs = Param.numMacro + Param.numMicro + Param.numPico;
Param.ueHeight = 1.5;% Double used to specify the height in metres of the UEs
Param.numUsers = 10;% Integer used for the number of UEs
Param.mobilityScenario = 'pedestrian';% Integer to choose the mobility scenario (pedestrian, pedestrian-indoor, vehicular, static, superman, straight)
Param.buildings = 'mobility/buildings.txt';% Path for loading the file with the buildings
Param.mobilityStep = 0.01;
Param.pucchFormat = 2;% PUCCH format (only 2 and 3 work)
Param.handoverTimer = 0.01;% X2 Handover timer in s (time needed from starting and handover to its completion)

%% Traffic
Param.primaryTrafficModel = 'webBrowsing'; % Primary traffic model ['fullBuffer', 'videoStreaming', 'webBrowsing']
Param.secondaryTrafficModel = 'videoStreaming'; % Secondary traffic model ['fullBuffer', 'videoStreaming', 'webBrowsing']
Param.trafficMix = 0.5; % Mix in the UEs between primary and secondary traffic models in %
Param.ueArrivalDistribution = 'Static'; % Arrival distribution for the UEs ['Poisson', 'Uniform', 'Static']
Param.poissonLambda = 5; % Mean of the Poisson process in ms
Param.uniformLower = 6; % Lower limit of the Uniform process in ms
Param.uniformUpper = 10; % Upper limit of the Uniform process in ms
Param.staticStart = 0; % Static start time in ms

%% Positioning (TR 36.872) - Only for "clusterized" microPos setting
Param.macroRadius = 250; % radius of the macro cell
Param.minUeDist = 20; % minimum distance between UEs and macro
Param.numClusters = 1; % number of clusters
Param.ueClusterRadius = 70; % radius of a cluster for UE placement
Param.microClusterRadius = 50; % radius of a cluster for micro placement
Param.minClusterDist = 105; % minimum distance between cluster center and macro
Param.interClusterDist = 100; % minimum distance between cluster centers
Param.microDist = 20; % minimum distance between micro cells
%% Physical layer
Param.ulFreq = 1747.5;% Double used for the uplink carrier frequency in MHz
Param.dlFreq = 1842.5;% Double used for the downlink carrier frequency in MHz
Param.prbSym = 160;% Integer used for the number of OFMD symbols in a RB
Param.ueNoiseFigure = 7;% Double used for the UE noise figure in dB
Param.eNBNoiseFigure = 7;% Double used for the BS noise figure in dB
Param.eNBGain = 0; %Antenna gain of the eNB.
Param.prbRe = 168;% Integer used for the number of RE in a RB
Param.PRACHInterval = 10; %Given as the number of subframes between each PRACH.
%% Channel configuration
Param.channel.modeDL = '3GPP38901';% String to control the channel mode in DL ['winner', 'eHATA', 'ITU1546', '3GPP38901']
Param.channel.modeUL = 'B2B';% String to control the channel mode in UL
Param.channel.region = 'Urban';% String to control the channel region
Param.channel.enableFading = true;
Param.channel.enableInterference = true;
Param.channel.enableShadowing = true; % Only capable for 3GPP38901
Param.channel.computeCoverage = false; %Only a visualization feature. Force the recomputation of the coverage, otherwise loaded from file if stored.
Param.channel.LOSMethod = '3GPP38901-probability'; % ['fresnel', '3GPP38901-probability']
% WINNER CONFIGURATION, only if 'winner is used'. See docs for the different varieties.
if strcmp(Param.channel.modeDL,'winner')
  Param.channel.region = struct();
	Param.channel.region.macroScenario = '11';
	Param.channel.region.microScenario = '3';
	Param.channel.region.picoScenario = '3';
elseif strcmp(Param.channel.modeDL, '3GPP38901')
	Param.channel.region = struct();
	Param.channel.region.macroScenario = 'UMa';
	Param.channel.region.microScenario = 'UMi';
	Param.channel.region.picoScenario = 'UMi';
end
%% SON parameters
Param.nboRadius = 100;% Double to set the maximum radius within which eNodeBs are considered as neighbours in metres
Param.tHyst = 0.001;% Double to set the hysteresis timer threshold in s
Param.tSwitch = 0.001;% Double to set the eNodeB switching on/off timer in s
Param.utilLoThr = 1;% Integer for the threshold for the low utilisation range (>= 1)
Param.utilHiThr = 100;% Integer for the threshold for the high utilisation range (<= 100)
Param.otaPowerScale = 1; % Value to scale the OTA power.

%% Scheduling
Param.scheduling = 'roundRobin';% String for the scheduling policy to use (currently only 'roundRobin')
Param.refreshAssociationTimer = 0.010;% Double to choose the interval in s to run refreshUsersAssociation
Param.icScheme = 'none';
Param.absMask = [1,0,1,0,0,0,0,0,0,0];

%%%%% SETUP STUFF - DON'T TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING
%% HARQ & ARQ
Param.harq.rtxMax = 3;% Integer to choose the maximum number of HARQ retransmissions
Param.harq.rv = [1,3,2];% Integer array for the redundacy version values
Param.harq.proc = 8;% Integer to choose the number of parallerl HARQ processes
Param.harq.tout = Param.harq.proc/2 -1;
Param.rtxOn = 1;% Boolean used to enable retransmissions
Param.arq.bufferFlusTimer = 20;% Timer for flushing out of place TBs in the RLC buffer in seconds
Param.arq.maxBufferSize = 1024;% Maximum number of TBs that the RLC can store at the same time as integer
Param.arq.rtxMax = 1;% Integer to choose the maximum number of ARQ retransmissions
%% PHY
Param.maxTbSize = 97896;% Double used for the maximum size of a TB for storing in bits
Param.maxCwdSize = 10e5;% Double used for the maximum size of a codeword for storing in bits
%% Buildings
Param.buildings = load(Param.buildings);
Param.buildingHeight = [20,50];% Double interval used to specify the height interval in metres of the buildings
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
	max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.buildingHeight],[1 length(Param.buildings(:,1))]);

save('SimulationParameters.mat', 'Param');
