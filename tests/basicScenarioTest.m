classdef basicScenarioTest < matlab.unittest.TestCase
	%Test for standard scenario with 1 user and 1 eNB
	properties
		Config;
		Logger;
		Simulation;
	end
	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config = MonsterConfig();
			%Make sure config fits the selected scenario
			%It should only be needed to change these in terms of runtime
			testCase.Config.Runtime.totalRounds = 50;
			testCase.Config.Runtime.seed = 126;
			%Skip plotting as values are going to be evaluated and not plots
			testCase.Config.SimulationPlot.runtimePlot = 0;
			%Set a single macroEnb
			testCase.Config.MacroEnb.sitesNumber = 1;
			testCase.Config.MacroEnb.cellsPerSite = 1;
			testCase.Config.MacroEnb.numPRBs = 50;
			testCase.Config.MacroEnb.height = 35;
			testCase.Config.MacroEnb.noiseFigure = 7;
			testCase.Config.MacroEnb.antennaGain = 0;
			%set 0 micro and pico Enb
			testCase.Config.MicroEnb.sitesNumber =0;
			%Set a single Ue
			testCase.Config.Ue.number = 1;
			testCase.Config.Ue.numPRBs = 25;
			testCase.Config.Ue.height = 1.5;
			testCase.Config.Ue.noiseFigure = 7;
			testCase.Config.Ue.antennaGain = 0;
			%Set mobility
			testCase.Config.Mobility.scenario = 'pedestrian';
			testCase.Config.Mobility.step = 0.01;
			testCase.Config.Mobility.seed = 19;
			%Set terrain
			testCase.Config.Terrain.type = 'city';
			%Set traffic to fullbuffer, to ensure that traffic is transmitted
			testCase.Config.Traffic.primary = 'fullBuffer';
			testCase.Config.Traffic.mix = 0;
			testCase.Config.Traffic.arrivalDistribution = 'Static';
			testCase.Config.Traffic.static = 0;
			%Set physical layer
			testCase.Config.Phy.uplinkFrequency = 1747.5;
			testCase.Config.Phy.downlinkFrequency = 1842.5;
			%Consider if this enough
			%set Channel properties
			testCase.Config.Channel.mode = '3GPP38901';
			testCase.Config.Channel.fadingActive = true;
			testCase.Config.Channel.interferenceType = 'Power'; %['Power', 'Frequency']
			testCase.Config.Channel.shadowingActive = true;
			testCase.Config.Channel.reciprocityActive = true;
			testCase.Config.Channel.perfectSynchronization = true;
			testCase.Config.Channel.losMethod = '3GPP38901-probability';
			testCase.Config.Channel.region = struct('type', 'Urban', 'macroScenario', 'UMa', 'microScenario', 'UMi', 'picoScenario', 'UMi');
			%Set scheduling
			testCase.Config.Scheduling.type = 'roundRobin';
			%Son Parameters
			testCase.Config.Son.neighbourRadius = 100;
			testCase.Config.Son.hysteresisTimer = 0.001;
			testCase.Config.Son.switchTimer = 0.001;
			testCase.Config.Son.utilisationRange = 1:100;
			testCase.Config.Son.utilLow = testCase.Config.Son.utilisationRange(1);
			testCase.Config.Son.utilHigh = testCase.Config.Son.utilisationRange(end);
			testCase.Config.Son.powerScale = 1;
			
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
			
			% Get a logger instance
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Simulation = Monster(testCase.Config, testCase.Logger);
			testCase.Config = testCase.Simulation.Config;
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
			testCase.verifyTrue( mean(testCase.Simulation.Results.util(2:end)) ==100); %First round util is 0, so that is omitted
			%verify power consumption and state
			%Power is calculated as CellReffP*P0+DeltaP*Pmax. This is 224W.
			arrayfun(@(x) testCase.verifyTrue(x == 224), testCase.Simulation.Results.powerConsumed);
			arrayfun(@(x) testCase.verifyEqual( x , 1), testCase.Simulation.Results.powerState); % powerState should be 1 in this case as it is always on
			%verify scheduling
			for i=2:testCase.Config.Runtime.totalRounds
				for j=1:testCase.Config.MacroEnb.numPRBs
					testCase.verifyEqual(testCase.Simulation.Results.schedule(i,1,j).UeId, 1); %Assert that UE 1 is scheduled all the time
					testCase.verifyEqual(testCase.Simulation.Results.schedule(i,1,j).NDI, true); %Asssert that New Data Indicator indicates that there are more data.
					%testCase.verifyTrue(testCase.Simulation.Results.schedule(i,1,j).ModOrd == 2 ||...
					%testCase.Simulation.Results.schedule(i,1,j).ModOrd == 4 ||...
					%testCase.Simulation.Results.schedule(i,1,j).ModOrd == 6 ); %TODO: examine how to assert this
					%testCase.verifyEqual(testCase.Simulation.Results.schedule(i,1,j).Mcs > 20); %TODO: examine how to assert this
				end
			end
			%verify HARQ and ARQ
			arrayfun(@(x) testCase.verifyEqual(x ,0), testCase.Simulation.Results.harqRtx); %Should be 0. With good signal strength retransmission should be 0
			arrayfun(@(x) testCase.verifyEqual(x ,0), testCase.Simulation.Results.arqRtx); %TODO: verify this statement
			%verify BER and BLER
			testCase.verifyTrue(mean(testCase.Simulation.Results.ber(2:end)) < 0.2 ); %Should be less than a certain threshhold. With good signal strength retransmission should be 0
			testCase.verifyTrue(mean(testCase.Simulation.Results.bler(2:end))< 0.2 ); %TODO: verify this statement
			%verify CQI
			arrayfun(@(x) testCase.verifyTrue(10 <= x && x <= 15) , testCase.Simulation.Results.cqi); %TODO: find a more narrow range and confirm
			%Verify SNR and SINR. With only 1 Enb they should be the same
			testCase.verifyTrue( mean(abs(testCase.Simulation.Results.snrdB - testCase.Simulation.Results.sinrdB) < 1e-4 )==1);
			%TODO: find a more appropiate range and/or verify current
			testCase.verifyTrue( 15 < mean(testCase.Simulation.Results.snrdB) && mean(testCase.Simulation.Results.snrdB) < 45 );
			%Verify difference between pre and post Evm
			testCase.verifyTrue(mean(testCase.Simulation.Results.preEvm > testCase.Simulation.Results.postEvm)==1);
			%Verify throughput
			testCase.verifyTrue( mean( testCase.Simulation.Results.throughput(2:end) > 1e8) == 1 ); %With 50 PRBs the throughput is expected to be in the 100mb/s range
			%Verify receivedPowerdBm
			testCase.verifyTrue( mean(-100 < testCase.Simulation.Results.receivedPowerdBm) && mean( testCase.Simulation.Results.receivedPowerdBm < -30) ); %TODO: narrow this range and verify
			%Verify rsrqdB, rsrpdBm, rssidBm is not unreasonable.
			testCase.verifyTrue( mean(-15 < testCase.Simulation.Results.rsrqdB) && mean(testCase.Simulation.Results.rsrqdB < 0) );
			testCase.verifyTrue( mean(-100 < testCase.Simulation.Results.rsrpdBm) && mean(testCase.Simulation.Results.rsrpdBm < -30) ); %TODO: narrow this range
			testCase.verifyTrue( mean(-100 < testCase.Simulation.Results.rssidBm) && mean(testCase.Simulation.Results.rssidBm < -30) ); %TODO: narrow this range
			%Verify that rsrpdBm and rssidBm values are related as expected
			testCase.verifyTrue( mean(-5 < (testCase.Simulation.Results.rsrpdBm-(testCase.Simulation.Results.rssidBm-10*log10(12*testCase.Simulation.Cells.NDLRB))))...
				&& mean( (testCase.Simulation.Results.rsrpdBm-(testCase.Simulation.Results.rssidBm-10*log10(12*testCase.Simulation.Cells.NDLRB))) < 5))
			testCase.verifyTrue( mean(-5 < (testCase.Simulation.Results.rssidBm-(testCase.Simulation.Results.rsrpdBm+10*log10(12*testCase.Simulation.Cells.NDLRB)))) ...
				&& mean((testCase.Simulation.Results.rssidBm-(testCase.Simulation.Results.rsrpdBm+10*log10(12*testCase.Simulation.Cells.NDLRB))) < 5))
		end
		
		
	end
	
end