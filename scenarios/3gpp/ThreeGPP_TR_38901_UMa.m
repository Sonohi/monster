clear all 

%% Get configuration
Config = MonsterConfig(); % Get template config parameters

%add scenario specific setup for '3GPP TR 38.901 UMa':
% from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-1, table 7.5-6 and table 7.8-1 on UMa
Config.Scenario = '3GPP TR 38.901 UMa';
Config.MacroEnb.ISD = 500;
Config.MacroEnb.sitesNumber = 19;
Config.MacroEnb.cellsPerSite = 1;
Config.MicroEnb.sitesNumber = 0;
Config.MacroEnb.height= 25;
Config.Ue.number = 30 * Config.MacroEnb.number; %Estimated, not mentioned directly
Config.Ue.height = 1.5;
Config.Channel.shadowingActive = 0;
Config.Channel.losMethod = 'NLOS';
%All users move with an avg of 3km/h
Config.Mobility.scenario = 'pedestrian';
Config.Mobility.Velocity = 0.8333; %0.8333[m/s]=3[km/h]
%Uniformly distributed users
%original scenario has 80% indoor users
%Minimum distance to BS = 35m
Config.Phy.downlinkFrequency = 6000; %6Ghz
%At 6GHz the BW is set to 20MHz, by this link 20MHz is 100 DL subframes http://www.sharetechnote.com/html/lte_toolbox/Matlab_LteToolbox_CellRS.html
%TODO: Check up on this statement, both above and below.
Config.MacroEnb.numPRBs = 100;
Config.MacroEnb.Pmax = 10^(49/10)/1e3; %49 dBm converted to W
%UT antenna configurations 1 element (vertically polarized), Isotropic antenna gain pattern 
Config.Ue.noiseFigure = 9; %dB
%Fast fading is not modelled?
%TODO: find out if fastfading and fading active is the same?
%Antenna arrays are:
%   Ue: [1 1 1 1 2] (2 polarization)
%   BS: [1 2 4 4 2] Mg=1, Ng=2, M=N=4, P=2
Logger = MonsterLog(Config);

% Setup objects
Simulation = Monster(Config, Logger);
%for iRound = 0:(Config.Runtime.totalRounds - 1)
%    Simulation.setupRound(iRound);
%    Simulation.run();
%    Simulation.collectResults();
%    Simulation.clean();

%end

