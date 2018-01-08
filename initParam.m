%% SIMULATION PARAMETERS
Param.reset = 0;% Boolean used to reset the folder structure and reload everything
Param.rmResults = 1;% Boolean to clean the results folder

% Boolean used to enable the drawing of plots and other cool stuff
Param.draw = 1;

% Booelan used to store the transmission data, that is each TB, codeword, waveform
Param.storeTxData = 0;

% Integer used to control the number of scheduling rounds (subframes) to simulate
Param.schRounds = 100;
Param.seed = 42;% Integer used for the simulation seed
% Boolean to save a whole LTE frame for the macro eNodeB for testing
Param.saveFrame = 1;

%% Network layout
Param.numSubFramesMacro = 50;% Integer used to set the number of RBs for a macro eNodeB
Param.numSubFramesMicro = 25;% Integer used to set the number of RBs for a micro eNodeB
Param.numSubFramesUE = 25;% Integer used to set the number of RBs for the uplink
Param.numMacro = 1;% Integer used to specify the number of macro eNodeBs in the scenario (currently only 1)
Param.numMicro = 2;% Integer used to specify the number of micro eNodeBs in the scenario
Param.microPos = 'uniform';% Array of char to deicde the positioning of the micro BS
Param.microUniformRadius = 100;% Double radius of distance from centre for microBS in metres
Param.macroHeight = 35;% Double used to specify the height in metres of the macro eNodeBs
Param.microHeight = 25;% Double used to specify the height in metres of the micro eNodeBs
Param.ueHeight = 1.5;% Double used to specify the height in metres of the UEs
Param.buildingHeight = [20,50];% Double interval used to specify the height interval in metres of the buildings
Param.numUsers = 4;% Integer used for the number of UEs
Param.mobilityScenario = 'superman';% Integer to choose the mobility scenario (pedestrian, vehicular, static, superman)
Param.buildings = 'mobility/buildings.txt';% Path for loading the file with the buildings
Param.utilLoThr = 1;% Integer for the threshold for the low utilisation range (>= 1)
Param.utilHiThr = 100;% Integer for the threshold for the high utilisation range (<= 100)
Param.trafficModel = 'fullBuffer';% Traffic model
%% Physical layer
Param.ulFreq = 1747.5;% Double used for the uplink carrier frequency in MHz
Param.dlFreq = 1842.5;% Double used for the downlink carrier frequency in MHz
Param.maxTbSize = 97896;% Double used for the maximum size of a TB for storing in bits
Param.maxCwdSize = 10e5;% Double used for the maximum size of a codeword for storing in bits
Param.maxSymSize = 10e5;% Double used for the maximum size of a list of OFDM symbols for storing
Param.prbSym = 160;% Integer used for the number of OFMD symbols in a RB
Param.ueNoiseFigure = 7;% Double used for the UE noise figure in dB
Param.bsNoiseFigure = 3;% Double used for the BS noise figure in dB
Param.prbRe = 168;% Integer used for the number of RE in a RB
%% Channel configuration
Param.channel.modeDL = 'winner';% String to control the channel mode in DL 
Param.channel.modeUL = 'B2B';% String to control the channel mode in UL
Param.channel.region = 'DenseUrban';% String to control the channel region
%% SON parameters
Param.nboRadius = 100;% Double to set the maximum radius within which eNodeBs are considered as neighbours in metres
Param.tHyst = 0.002;% Double to set the hysteresis timer threshold in s
Param.tSwitch = 0.001;% Double to set the eNodeB switching on/off timer in s
Param.icScheme = 'none';% String to choose the intereference coordination scheme (currently only 'none')

%% Draw functions
Param.generateHeatMap = 0;% Boolean to control the generation of a heatmap of the pathloos in the scenario
Param.heatMapType = 'perStation';% String to control the type of heatmap
Param.heatMapRes = 10;% Heatmap resoultion in metres

%% Scheduling
Param.scheduling = 'roundRobin';% String for the scheduling policy to use (currently only 'roundRobin')
Param.refreshAssociationTimer = 0.001;% Double to choose the interval in s to run refreshUsersAssociation
Param.PRACHInterval = 10; %Given as the number of subframes between each PRACH.

%% HARQ
Param.harq.rtxMax = 3;% Integer to choose the maximum number of HARQ retransmissions
Param.harq.rv = [1,3,2];% Integer array for the redundacy version values
Param.harq.proc = 8;% Integer to choose the number of parallerl HARQ processes
Param.rtxOn = 1;% Boolean used to enable retransmissions
Param.arq.bufferFlusTimer = 20;% Timer for flushing out of place TBs in the RLC buffer in seconds
Param.arq.maxBufferSize = 1024;% Maximum number of TBs that the RLC can store at the same time as integer
Param.arq.rtxMax = 1;% Integer to choose the maximum number of ARQ retransmissions
Param.pucchFormat = 2;% PUCCH format (only 2 and 3 work)
Param.handoverTimer = 0.01;% X2 Handover timer in s (time needed from starting and handover to its completion)


%%%%% SETUP STUFF - DON'T TOUCH UNLESS YOU KNOW WHAT YOU'RE DOING
Param.buildings = load(Param.buildings);
Param.area = [min(Param.buildings(:, 1)), min(Param.buildings(:, 2)), ...
	max(Param.buildings(:, 3)), max(Param.buildings(:, 4))];
Param.buildings(:,5) = randi([Param.buildingHeight],[1 length(Param.buildings(:,1))]);

Param.harq.tout = Param.harq.proc/2 -1;

% Get traffic source data and check if we have already the MAT file with the traffic data
switch Param.trafficModel
	case 'videoStreaming'
		if (exist('traffic/videoStreaming.mat', 'file') ~= 2 || Param.reset)
			trSource = loadVideoStreamingTraffic('traffic/videoStreaming.csv', true);
		else
			load('traffic/videoStreaming.mat', 'trSource');
		end
	case 'fullBuffer'
		if (exist('traffic/fullBuffer.mat', 'file') ~= 2 || Param.reset)
			trSource = loadFullBufferTraffic('traffic/fullBuffer.csv');
		else
			load('traffic/fullBuffer.mat', 'trSource');
		end
end
