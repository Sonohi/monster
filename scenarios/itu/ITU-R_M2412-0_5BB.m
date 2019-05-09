clear all 

%% Get configuration
Config = MonsterConfig(); % Get template config parameters

%add scenario specific setup for 'ITU-R M2412-0 5.B.B': 
% from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.c Configuration B
%For Spectral efficiency and mobility Evaluations.
Config.Scenario = 'ITU-R M.2412-0 5.B.B';
Config.MacroEnb.number = 19;
Config.MicroEnb.number = 0;
Config.PicoEnb.number = 0;				
Config.Phy.downlinkFrequency = 30000; %MHz
Config.MacroEnb.height= 25;
Config.MacroEnb.Pmax = 10^(37/10)/1e3; %37dBm converted to W
%TODO: make 40MHz bandwidth possible
Config.MacroEnb.numPRBs = 100; % should be 200 corresponding to 40MHz bandwidth
%Ue Transmit power in dBm = 23. 
%Percentage of high loss and low loss: 20/80 (high/low)
Config.MacroEnb.ISD = 200; %intersite distance in meters
%Number of antenna elements per TRxP: up to 256 Tx/Rx
%Number of Ue antenna element: Up to 8 Tx/Rx
%Device deployment: 80/20 (indoor/outdoor - in car)
%Mobility modelling: Fixed and idential speed v of all UEs, random direction
%UE speed: indoor: 3km/h    outdoor: 30km/h (in car)
Config.Mobility.scenario = 'pedestrian';
Config.Mobility.Velocity = 0.8333;
Config.MacroEnb.noiseFigure = 7; %dB
Config.Ue.noiseFigure = 10; %dB (10dB assumes high performance UE)
Config.MacroEnb.antennaGain = 8; % dBi
Config.Ue.antennaGain = 5; %dBi
%Thermal noise = -174dBm/Hz
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0; %0-> no mix, only primary
%Simulation bandwidth: 20 MHz for TDD, 10 MHz+10 MHz for FDD
Config.Ue.number = 10 * Config.MacroEnb.number;
Config.Ue.height = 1.5; %meters	
Logger = MonsterLog(Config);

% Setup objects
Simulation = Monster(Config, Logger);
for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);
	Simulation.run();
	Simulation.collectResults();
	Simulation.clean();
end

