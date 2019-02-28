function ApplyScenario(Config)


%Check for scenario
switch Config.Scenario.scenario
    %TODO: make a function or class for readability
case '3GPP TR 38.901 UMa' 
    % from https://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf Table 7.2-1, table 7.5-6 and table 7.8-1 on UMa
    obj.Scenario = '3GPP TR 38.901 UMa';
    Config.MacroEnb.radius = 500;
    Config.MacroEnb.number = 19;
    Config.MicroEnb.number = 0;
    Config.PicoEnb.number = 0;
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
    Config.MacroEnb.subframes = 100;
    Config.MacroEnb.Pmax = 10^(49/10)/1e3 %49 dBm converted to W
    %UT antenna configurations 1 element (vertically polarized), Isotropic antenna gain pattern 
    Config.Ue.noiseFigure = 9; %dB
    %Fast fading is not modelled?
    %TODO: find out if fastfading and fading active is the same?


case 'ITU-R M2412-0 5.B.A' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.c Configuration A
    %For Spectral efficiency and mobility Evaluations.
    obj.Scenario = 'ITU-R M.2412-0 5.B.A';
    Config.MacroEnb.number = 19;
    Config.MicroEnb.number = 0;
    Config.PicoEnb.number = 0;				
    Config.Phy.downlinkFrequency = 4000; %MHz
    Config.MacroEnb.height= 25;
    Config.MacroEnb.Pmax = 10^(41/10)/1e3; %41dBm converted to W
    Config.MacroEnb.subframes = 50; % 10MHz bandwidth
    %Ue Transmit power in dBm = 23. 
    %Percentage of high loss and low loss: 20/80 (high/low)
    Config.MacroEnb.radius = 200; %intersite distance in meters
    %Number of antenna elements per TRxP: up to 256 Tx/Rx
    %Number of Ue antenna element: Up to 8 Tx/Rx
    %Device deployment: 80/20 (indoor/outdoor - in car)
    %Mobility modelling: Fixed and idential speed v of all UEs, random direction
    %UE speed: indoor: 3km/h    outdoor: 30km/h (in car)
    Config.Mobility.scenario = 'pedestrian';
    Config.Mobility.Velocity = 0.8333;
    Config.MacroEnb.noiseFigure = 5; %dB
    Config.Ue.noiseFigure = 7; %dB
    Config.MacroEnb.antennaGain = 8; % dBi
    Config.Ue.antennaGain = 0; %dBi
    %Thermal noise = -174dBm/Hz
    Config.Traffic.primary = 'fullBuffer';
    Config.Traffic.mix = 0; %0-> no mix, only primary
    %Simulation bandwidth: 20 MHz for TDD, 10 MHz+10 MHz for FDD
    Config.Ue.number = 10 * Config.MacroEnb.number;
    Config.Ue.height = 1.5; %meters
    
case 'ITU-R M2412-0 5.B.B' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.c Configuration B
    %For Spectral efficiency and mobility Evaluations.
    obj.Scenario = 'ITU-R M.2412-0 5.B.B';
    Config.MacroEnb.number = 19;
    Config.MicroEnb.number = 0;
    Config.PicoEnb.number = 0;				
    Config.Phy.downlinkFrequency = 30000; %MHz
    Config.MacroEnb.height= 25;
    Config.MacroEnb.Pmax = 10^(37/10)/1e3; %37dBm converted to W
    %TODO: make 40MHz bandwidth possible
    Config.MacroEnb.subframes = 100; % should be 200 corresponding to 40MHz bandwidth
    %Ue Transmit power in dBm = 23. 
    %Percentage of high loss and low loss: 20/80 (high/low)
    Config.MacroEnb.radius = 200; %intersite distance in meters
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

case 'ITU-R M.2412-0 5.B.C' % from https://www.itu.int/dms_pub/itu-r/opb/rep/R-REP-M.2412-2017-PDF-E.pdf Table 5.b Configuration C
    %User Experienced Data Rate Evaluation
    obj.Scenario = 'ITU-R M.2412-0 5.B.C';
    Config.MacroEnb.radius = 200;
    Config.MacroEnb.number = 19;
    Config.MicroEnb.number = 9*Config.MacroEnb.number;
    Config.PicoEnb.number = 0;
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
    Config.MacroEnb.subframes = 50 % 50 subframes =10MHz bandwidth
    Config.MacroEnb.Pmax = 10^(41/10)/1e3 ;%41dBm converted to W
    %For micro the chosen scenario is 4GHz and 10MHz bandwidth
    Config.MicroEnb.subframes = 50 ; %50 subframes = 10MHz Bandwidth
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

case 'Single Cell' % Deploys a single cell for testing purposes.
    obj.Scenario = 'Single Cell';
    Config.MacroEnb.radius = 300;
    Config.MacroEnb.number = 1;
    Config.MicroEnb.number = 0;
    Config.PicoEnb.number = 0; 
    Config.MacroEnb.height= 35;
    Config.Ue.number = 1;
    Config.Ue.height = 1.5;
    Config.Traffic.primary = 'fullBuffer';
    Config.Traffic.mix = 0;
    %TODO: Add more specifics, to make sure, that no matter the Config, this allways works
    
otherwise
    obj.Scenario = 'None';

end






end