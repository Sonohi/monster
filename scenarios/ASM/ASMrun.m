clear all 

%% Get configuration
Config = MonsterConfig(); % Get template config parameters

Config.Logs.logToFile = 1; % 0 only console | 1 only file | 2 both

%ASM paper duplication
Config.Scenario = 'ASM_reproduction';
Config.MacroEnb.sitesNumber = 19;
Config.MacroEnb.cellsPerSite = 3;
Config.MacroEnb.numPRBs = 100; %50 corresponds to a bandwidth of 10MHz
Config.MacroEnb.height = 30;
Config.MacroEnb.positioning = 'centre';
Config.MacroEnb.ISD = 500; %intersite distance in meters
Config.MacroEnb.Pmax = 10^(46/10)/1e3; %46dBm converted to W

%Thermal noise = -174dBm/Hz
Config.MacroEnb.noiseFigure = 5; %dB
Config.Ue.noiseFigure = 7; %dB
Config.MacroEnb.antennaGain = 8; % dBi
Config.Ue.antennaGain = 0; %dBi

%Ue Transmit power in dBm = 23. 
%Percentage of high loss and low loss: 20/80 (high/low)

%off all other BS
Config.MicroEnb.sitesNumber = 0;

%Number of antenna elements per TRxP: up to 256 Tx/Rx
%Number of Ue antenna element: Up to 8 Tx/Rx
%Device deployment: 80/20 (indoor/outdoor - in car)
%Mobility modelling: Fixed and idential speed v of all UEs, random direction
%UE speed: indoor: 3km/h    outdoor: 30km/h (in car)
Config.Mobility.scenario = 'pedestrian';
Config.Mobility.Velocity = 0.01;

Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0; %0-> no mix, only primary
Config.Traffic.arrivalDistribution = 'Poisson'; % Static | Uniform | Poisson
Config.Traffic.poissonLambda = 60;

%Simulation bandwidth: 20 MHz for TDD, 10 MHz+10 MHz for FDD
Config.Ue.number = 20; %TODO: 14 different from 1 to 60
Config.Ue.height = 1.5; %meters

Logger = MonsterLog(Config);
    
% Setup objects
Simulation = Monster(Config, Logger);
for iRound = 0:(Config.Runtime.simulationRounds - 1)
    Simulation.setupRound(iRound);
    Simulation.run();
    Simulation.collectResults();
    Simulation.clean();
end

