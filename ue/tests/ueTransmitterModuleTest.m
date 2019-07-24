classdef ueTransmitterModuleTest < matlab.unittest.TestCase
	
	properties
		Config;
		TxModule;
		RxModule;
		Stations;
		Channel;
		Users;
		Logger;
		Monster;
	end
	
	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.MacroEnb.number = 1;
			testCase.Config.MicroEnb.number = 0;
			testCase.Config.Ue.number = 1;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Monster = Monster(testCase.Config, testCase.Logger);
		
			
		end
	end
	
	methods(TestMethodTeardown)
		function resetTransmitters(testCase)
			testCase.Monster.clean();
		end
	end
	
	methods(TestMethodSetup)
		function setUplinkWaveform(testCase)
			testCase.Monster.associateUsers();
			testCase.Monster.schedule();
			testCase.Monster.setupUeTransmitters();
			testCase.Monster.uplinkTraverse();
			testCase.Monster.uplinkEnbReception();
		end
		
	end
	
	methods (Test)
		
		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.Monster.Users.Tx, 'ueTransmitterModule'));
		end
		
		function testModulation(testCase)
			% Test that grid is modulated and can be demodulated
			ue = testCase.Monster.Users(1);
			waveform = ue.Tx.Waveform;
			
			% Demodulate waveform
			demodGrid = lteSCFDMADemodulate(struct(ue), waveform);
			diffGrid = demodGrid - ue.Tx.ReGrid;
			
			% Compute difference, if smaller than threshold value we assume
			% they're equal.
			if abs(sum(sum(diffGrid))) < 1e-12
				demod = true;
			else
				demod = false;
			end
			
			testCase.verifyTrue(demod)
		end
		
		function testModulationError(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.reset()% No grid set
			testCase.verifyError(@() ue.Tx.modulateResourceGrid(),'MonsterUeTransmitterModule:EmptySubframe');
		end
		
		function testSRSConfiguration(testCase)
			% Set SRS configuration
			ue = testCase.Monster.Users(1);
			C_SRS = 3;
			B_SRS = 3;
			subframeConfig = 3; 
			[srsStruct, srsInfo] = ue.Tx.setupSRSConfig(C_SRS, B_SRS, subframeConfig);
			
			testCase.verifyEqual(srsStruct.BWConfig, C_SRS);
			testCase.verifyEqual(srsStruct.BW, B_SRS);
			testCase.verifyEqual(srsStruct.SubframeConfig, subframeConfig);
			
			% Per table 8.2-4 in 36213 for FDD
			% MATLAB uses a different table allocation (maybe a prior release),
			% thus the mapping is
			% 0 = 1 ms
			% 1-2 = 2 ms
			% 3-8 = 5 ms
			% 9-14 = 10 ms
			% 15 = 1 ms
			testCase.verifyEqual(double(srsInfo.CellPeriod), 5);
			
			subframeConfig = 14; 
			[srsStruct, srsInfo] = ue.Tx.setupSRSConfig(C_SRS, B_SRS, subframeConfig);
			testCase.verifyEqual(double(srsInfo.CellPeriod), 10);
			
			subframeConfig = 1; 
			[srsStruct, srsInfo] = ue.Tx.setupSRSConfig(C_SRS, B_SRS, subframeConfig);
			testCase.verifyEqual(double(srsInfo.CellPeriod), 2);
			
		end
		
		function testSRSplacement(testCase)
			% Test SRS sequence is generated correctly
		end
		
		function testSRSReferenceEstimation(testCase)
			% Test SRS sequence is used properly in the channel estimator.
		end
		
		function testPUUSCHConfiguration(testCase)
			
		end
		
		
		
	end
	
	
end