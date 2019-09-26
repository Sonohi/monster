classdef simulationTest < matlab.unittest.TestCase
	%Test for simulation
	properties
		Config;
		Logger;
		Simulation;
	end
	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config = MonsterConfig();
			testCase.Config.SimulationPlot.runtimePlot = 0;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Simulation = Monster(testCase.Config, testCase.Logger);
		end
	end
	
	
	methods (Test)
		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.Simulation, 'Monster'));
		end
		
		function testSetupRound(testCase)
			%Setup simulation for round 0
			iRound = 0;
			testCase.Simulation.setupRound(iRound);
			testCase.verifyTrue(testCase.Simulation.Runtime.currentRound == iRound);
			testCase.verifyTrue(testCase.Simulation.Runtime.currentTime == iRound*10e-3);
			testCase.verifyTrue(testCase.Simulation.Runtime.remainingTime == (testCase.Simulation.Runtime.totalRounds - testCase.Simulation.Runtime.currentRound)*10e-3);
			testCase.verifyTrue(testCase.Simulation.Runtime.remainingRounds == testCase.Simulation.Runtime.totalRounds - testCase.Simulation.Runtime.currentRound - 1);
			
			%TODO: Test for channel setup as well?
		end
		
		function testRun(testCase)
			
			%Run the simulation loop
			testCase.Simulation.run();
			
		end
		
		function testCollectResults(testCase)
			testCase.Simulation.collectResults();
			
		end
		
		function testClean(testCase)
			testCase.Simulation.clean();
			%Test that cells and users are reset
			%Test Cells
			arrayfun(@(x) testCase.verifyEqual(x.NSubframe, mod(1,10)) , testCase.Simulation.Cells);
			
			for iCell = 1:length(testCase.Simulation.Cells)
				clear temp;
				temp(1:testCase.Simulation.Cells(iCell).NDLRB,1) = struct('UeId', -1, 'Mcs', -1, 'ModOrd', -1, 'NDI', 1);
				testCase.verifyEqual(testCase.Simulation.Cells(iCell).ScheduleDL  , temp );
			end
			
			arrayfun(@(x) testCase.verifyEqual(x.Tx.Ref ,struct('ReGrid',[], 'Waveform',[], 'WaveformInfo',[],'PSSInd',[],'PSS', [],'SSS', [],'SSSInd',[],'PSSWaveform',[], 'SSSWaveform',[])), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Tx.ReGrid , []), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Tx.Waveform ,[]), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Tx.WaveformInfo ,[]), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.UeData, []), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Waveform, []), testCase.Simulation.Cells);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.RxPwdBm, []), testCase.Simulation.Cells);
			
			%Test Ue
			arrayfun(@(x) testCase.verifyEqual(x.Scheduled, struct('DL', false, 'UL', false)), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Symbols, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.SymbolsInfo, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Codeword, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.CodewordInfo, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.TransportBlock, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.TransportBlockInfo, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Tx.Waveform, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Tx.ReGrid, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.NoiseEst, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.RSSIdBm, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.RSRQdB, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.RSRPdBm, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyTrue(isempty(fieldnames(x.Rx.ChannelConditions))), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Subframe, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.EstChannelGrid, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.EqSubframe, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.TransportBlock, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Crc, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.PreEvm, 0 ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.PostEvm, 0 ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.BLER, 0 ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Throughput, 0 ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.SchIndexes, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.PDSCH, [] ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Blocks, struct('ok', 0, 'err', 0, 'tot', 0) ), testCase.Simulation.Users);
			arrayfun(@(x) testCase.verifyEqual(x.Rx.Bits, struct('ok', 0, 'err', 0, 'tot', 0) ), testCase.Simulation.Users);
			
		end
	end
	
end