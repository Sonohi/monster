clear all 

%% Get configuration
Config = MonsterConfig(); % Get template config parameters

%add scenario specific setup for 'ITU-R M.2412-0 5.B.C' 
% from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.b Configuration C
%User Experienced Data Rate Evaluation
Config.Scenario = 'ITU-R M.2412-0 5.B.C';
Config.MacroEnb.ISD = 200;
Config.MacroEnb.sitesNumber = 19;
Config.MacroEnb.cellsPerSite = 1;
Config.MicroEnb.sitesNumber = 9*Config.MacroEnb.number;
Config.MacroEnb.height= 25;
Config.microHeight = 10;
Config.Ue.height = 1.5;
Config.Ue.number = 10 * Config.MacroEnb.number;
Config.Traffic.primary = 'fullBuffer';
Config.Traffic.mix = 0; %0 mix, means only primary mode
%Perhaps larger building grid??
%Carrier frequency: 4 GHz and 30 GHz available in macro and micro layers
%Total transmit power per TRxP:  -Macro 4 GHz:
																%   44 dBm for 20 MHz bandwidth
																%   41 dBm for 10 MHz bandwidth
																%-Macro 30 GHz:
																%   40 dBm for 80 MHz bandwidth
																%   37 dBm for 40 MHz bandwidth
																%e.i.r.p. should not exceed 73 dBm
																%-Micro 4 GHz:
																%   33 dBm for 20 MHz bandwidth
																%   30 dBm for 10 MHz bandwidth
																%-Micro 30 GHz:
																%   33 dBm for 80 MHz bandwidth
																%   30 dBm for 40 MHz bandwidth
																%e.i.r.p. should not exceed 68 dBm
%The chosen scenario is for 10MHz bandwidth at 4GHz for macro
Config.Phy.downlinkFrequency = 4000; %4GHz
Config.MacroEnb.numPRBs = 50 % 50 subframes =10MHz bandwidth
Config.MacroEnb.Pmax = 10^(41/10)/1e3 ;%41dBm converted to W
%For micro the chosen scenario is 4GHz and 10MHz bandwidth
Config.MicroEnb.numPRBs = 50 ; %50 subframes = 10MHz Bandwidth
Config.MicroEnb.Pmax = 10^(30/10)/1e3; % 30 dBm converted to W
%UE power class: 4 GHz: 23 dBm, 30 GHz: 23 dBm, e.i.r.p. should not exceed 43 dBm
%Ue Transmit power in dBm = 23. 
%Percentage of high and low loss building type: 20% high loss, 80% low loss
%Number of antenna elements per TRxP: 256 Tx/Rx
%Number of UE Antenna elements: 4 GHz: Up to 8 Tx/Rx, 30 GHz: Up to 32 Tx/Rx
% 80% indoor, 20% outdoor (in car)
%Mobility modelling: Fixed and idential speed v of all UEs, random direction
%UE speed: indoor: 3km/h    outdoor: 30km/h (in car)
Config.Mobility.scenario = 'pedestrian';
Config.Mobility.Velocity = 0.8333;

%BS noise figure: 4GHz -> 5dB
								%30GHz -> 7dB
Config.MacroEnb.noiseFigure = 5; %dB
%UE noise figure: 4GHz -> 7dB
								%30GHz -> 10dB (assumed for high performance UEs. For low performance 13 dB could be considered)
Config.Ue.noiseFigure = 7; %dB
%BS antenna element gain: 4GHz -> 8dBi, 30GHz -> Macro TRxP: 8dBi
Config.MacroEnb.antennaGain = 8; %dBi
Config.MicroEnb.antennaGain = 8; %dBi
%UE antenna element gain: 4GHz -> 0dBi, 30GHz -> 5dBi
Config.Ue.antennaGain = 0; %dBi
%Thermal noise: -174 dBm/Hz
%Bandwidths: 4GHz -> 20MHz for TDD or 10MHz + 10MHz for FDD
%           30GHz -> 80MHz for TDD or 40MHz + 40MHz for FDD
%UE density: 10 UEs per TRxP
% Setup objects
Logger = MonsterLog(Config);
Simulation = Monster(Config, Logger);
for iRound = 0:(Config.Runtime.totalRounds - 1)
	Simulation.setupRound(iRound);
	Simulation.run();
	Simulation.collectResults();
	Simulation.clean();
end

