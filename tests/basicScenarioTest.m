classdef basicScenarioTest < matlab.unittest.TestCase
    %Test for standard scenario with 1 user and 1 eNB
    properties 
        Config;
        Simulation;
    end
    methods (TestClassSetup)
        function createObjects(testCase)
            testCase.Config = MonsterConfig();
            %Make sure config fits the selected scenario
            %It should only be needed to change these in terms of runtime
            testCase.Config.Runtime.numRounds =50;
            testCase.Config.Runtime.seed = 126; 
            %Skip plotting as values are going to be evaluated and not plots
            testCase.Config.SimulationPlot.runtimePlot = 0;
			testCase.Config.SimulationPlot.generateCoverageMap = 0;
            testCase.Config.SimulationPlot.generateHeatMap = 0;
            %Set a single macroEnb
            testCase.Config.MacroEnb.number = 1;
            testCase.Config.MacroEnb.subframes = 50;
            testCase.Config.MacroEnb.height = 35;
            testCase.Config.MacroEnb.noiseFigure = 7;
            testCase.Config.MacroEnb.antennaGain = 0;
            %set 0 micro and pico Enb
            testCase.Config.MicroEnb.number =0;
            testCase.Config.PicoEnb.number =0;
            %Set a single Ue
            testCase.Config.Ue.number = 1;
			testCase.Config.Ue.subframes = 25;
			testCase.Config.Ue.height = 1.5;
			testCase.Config.Ue.noiseFigure = 7;
			testCase.Config.Ue.antennaGain = 0;
            %Set mobility
            testCase.Config.Mobility.scenario = 'pedestrian';
			testCase.Config.Mobility.step = 0.01;
            testCase.Config.Mobility.seed = 19;
            %Set terrain
            testCase.Config.Terrain.buildingsFile = 'mobility/buildings.txt';
			testCase.Config.Terrain.heightRange = [20,50];
			testCase.Config.Terrain.buildings = load(testCase.Config.Terrain.buildingsFile);
			testCase.Config.Terrain.buildings(:,5) = randi([testCase.Config.Terrain.heightRange],[1 length(testCase.Config.Terrain.buildings(:,1))]);
			testCase.Config.Terrain.area = [...
				min(testCase.Config.Terrain.buildings(:, 1)), ...
				min(testCase.Config.Terrain.buildings(:, 2)), ...
				max(testCase.Config.Terrain.buildings(:, 3)), ...
				max(testCase.Config.Terrain.buildings(:, 4))];
            %Set traffic to fullbuffer, to ensure that traffic is transmitted
            testCase.Config.Traffic.primary = 'fullBuffer';
            testCase.Config.Traffic.mix = 0;
            %Set physical layer
            testCase.Config.Phy.uplinkFrequency = 1747.5;
			testCase.Config.Phy.downlinkFrequency = 1842.5;
            %Consider if this enough
            %set Channel properties
            testCase.Config.Channel.mode = '3GPP38901';
			testCase.Config.Channel.fadingActive = true;
			testCase.Config.Channel.interferenceType = 'Full';
			testCase.Config.Channel.shadowingActive = true;
			testCase.Config.Channel.reciprocityActive = true;
			testCase.Config.Channel.perfectSynchronization = true;
			testCase.Config.Channel.losMethod = '3GPP38901-probability';
			testCase.Config.Channel.region = struct('type', 'Urban', 'macroScenario', 'UMa', 'microScenario', 'UMi', 'picoScenario', 'UMi');
            %Set scheduling
            testCase.Config.Scheduling.type = 'roundRobin';
            %Set HARQ and ARQ
            testCase.Config.Harq.active = true;
			testCase.Config.Harq.maxRetransmissions = 3;
			testCase.Config.Harq.redundacyVersion = [1, 3, 2];
			testCase.Config.Harq.processes = 8;
            testCase.Config.Harq.timeout = 3;
            testCase.Config.Arq.active = true;
			testCase.Config.Arq.maxRetransmissions = 1;
			testCase.Config.Arq.maxBufferSize = 1024;
            testCase.Config.Arq.timeout = 20;
            
            testCase.Simulation = Monster(testCase.Config);
        end
    end

    methods (TestMethodTeardown)
        function resetObjects(testCase)
            %Test Teardown

        end
    end

    methods (Test)


        function testResults(testCase)
            %Run simulation
            for iRound = 0:(testCase.Config.Runtime.totalRounds - 1)
                testCase.Simulation.setupRound(iRound);
                testCase.Simulation.run();          
                testCase.Simulation.collectResults();
                testCase.Simulation.clean();
            end
            %Verify results
            %Verify utilization
            testCase.verifyTrue( mean(testCase.Simulation.Results.util(2:end)) >=100); %First round util is 0, so that is omitted
            %verify power consumption and state
            testCase.verifyTrue(mean(testCase.Simulation.Results.powerConsumed) >= 224); %TODO: precise prediction of this value
            testCase.verifyEqual( mean(testCase.Simulation.Results.powerState), 1);
            %verify scheduling
            %testCase.verifyEqual(testCase.Simulation.Results.schedule, ???); %TODO: find a proper way to do this
            %verify HARQ and ARQ
            %TODO: Find a proper solution for this.
            %verify BER and BLER
            %TODO: Find a proper solution for this.
            %verify CQI
            arrayfun(@(x) testCase.verifyTrue(0 <= x && x <= 15) , testCase.Simulation.Results.cqi); %TODO: find a more narrow range
            %Verify SNR and SINR. With only 1 Enb they should be the same
            testCase.verifyTrue( any(abs(testCase.Simulation.Results.snrdB - testCase.Simulation.Results.sinrdB) < 1e-4 ));
            testCase.verifyTrue( 0 < mean(testCase.Simulation.Results.snrdB) && mean(testCase.Simulation.Results.snrdB) < 50 ); %TODO: find a more appropiate range
            %Verify difference between pre and post Evm
            testCase.verifyTrue(any(testCase.Simulation.Results.preEvm > testCase.Simulation.Results.postEvm));
            %Verify throughput
            testCase.verifyTrue( any( testCase.Simulation.Results.throughput(2:end) > 1e8) ); %With 50 PRBs the throughput is expected to be in the 100mb/s range
            %Verify receivedPowerdBm
            testCase.verifyTrue( any(-100 < testCase.Simulation.Results.receivedPowerdBm) && any( testCase.Simulation.Results.receivedPowerdBm < -30) ); %TODO: narrow this range
            %Verify rsrqdB, rsrpdBm, rssidBm
            testCase.verifyTrue( any(-100 < testCase.Simulation.Results.rsrqdB) && any(testCase.Simulation.Results.rsrqdB < 0) ); %TODO: narrow this range
            testCase.verifyTrue( any(-100 < testCase.Simulation.Results.rsrpdBm) && any(testCase.Simulation.Results.rsrpdBm < -30) ); %TODO: narrow this range
            testCase.verifyTrue( any(-100 < testCase.Simulation.Results.rssidBm) && any(testCase.Simulation.Results.rssidBm < -30) ); %TODO: narrow this range

        end


    end

end