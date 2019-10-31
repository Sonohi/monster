classdef ueTransmitterModuleTest < matlab.unittest.TestCase
	
	properties
		Config;
		TxModule;
		RxModule;
		Cells;
		Channel;
		Users;
		Logger;
		Monster;
		MonsterSRSdisabled;
	end
	
	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.MacroEnb.number = 1;
			testCase.Config.MicroEnb.number = 0;
			testCase.Config.Ue.number = 1;
			testCase.Config.SRS.active = true;
			testCase.Config.SimulationPlot.runtimePlot = 0;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Monster = Monster(testCase.Config, testCase.Logger);
		
			% Disabled SRS Monster instance
			testCase.Config.SRS.active = false;
			testCase.MonsterSRSdisabled = Monster(testCase.Config, testCase.Logger);
			
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
			testCase.Monster.scheduleUL();
		end
		
	end
	
	methods (Test)
		
		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.Monster.Users.Tx, 'ueTransmitterModule'));
		end
		
		function testModulation(testCase)
			% Test that grid is modulated and can be demodulated
			testCase.Monster.setupUeTransmitters();
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
			
			testCase.verifyTrue(demod);
		end
		
		function testSetupResourceGrid(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.ReGrid = zeros(9,9);
			testCase.verifyError(@() ue.Tx.setupResourceGrid(), 'ueTransmitterModule:ExpectedEmptyResourceGrid')
		end
		
		function testModulationError(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.reset();% No grid set
			testCase.verifyError(@() ue.Tx.modulateResourceGrid(),'MonsterUeTransmitterModule:EmptySubframe');
		end
		
		function testEIRPdBm(testCase)
			ue = testCase.Monster.Users(1);
			testCase.verifyEqual(ue.Tx.getEIRPdBm, (ue.Tx.TxPwdBm + ue.Tx.Gain));
		end
		
		function testSRSConfiguration(testCase)
			% Set SRS configuration
			ue = testCase.Monster.Users(1);
			C_SRS = 0;
			B_SRS = 7;
			subframeConfig = 3; 
			[srsStruct, srsInfo] = ue.Tx.setupSRSConfig(C_SRS, B_SRS, subframeConfig);
			
			testCase.verifyEqual(srsStruct.BWConfig, C_SRS);
			testCase.verifyEqual(srsStruct.BW, B_SRS);
			testCase.verifyEqual(srsStruct.SubframeConfig, subframeConfig);
		
			% Per table 8.2-4 in 36213 for FDD
			% MATLAB uses a different table allocation (maybe a prior release),
			% thus the mapping of subframeConfig is
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

		function testSRSdisabled(testCase)
			% Test that SRS is not generated
			ue = testCase.MonsterSRSdisabled.Users(1);
			ue.Tx.setupTransmission();

			testCase.verifyEmpty(ue.Tx.Ref.srsIdx);
		end
		
		function testSRSisStored(testCase)
			% Test SRS sequence is stored in reference structure
			ue = testCase.Monster.Users(1);
			ue.Tx.setupTransmission();
			testCase.verifyNotEmpty(ue.Tx.Ref.srsIdx);
			testCase.verifyNotEmpty(ue.Tx.Ref.Grid(ue.Tx.Ref.srsIdx));
		end
		
		function testPUSCHDRSisStored(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.setupTransmission();
			
			if ~isempty(ue.Tx.PUSCH.PRBSet)
				testCase.verifyNotEmpty(ue.Tx.Ref.puschDRSIdx);
				testCase.verifyNotEmpty(ue.Tx.Ref.Grid(ue.Tx.Ref.puschDRSIdx));
			else
				testCase.verifyEmpty(ue.Tx.Ref.puschDRSIdx);
				testCase.verifyEmpty(ue.Tx.Ref.Grid(ue.Tx.Ref.puschDRSIdx));
			end
			
		end
		
		function testPUSCHBitGeneration(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.setupResourceGrid();
			ue.Tx.setupControlSignals();
			%ue.Tx.generatePUSCHBits();
			
			
		end 
		
		function testPUCCHDRSisStored(testCase)
			ue = testCase.Monster.Users(1);
			ue.Tx.setupTransmission();
			
			testCase.verifyNotEmpty(ue.Tx.Ref.pucchDRSIdx);
			testCase.verifyNotEmpty(ue.Tx.Ref.Grid(ue.Tx.Ref.pucchDRSIdx));  
		end
		
		
	end
	
	
end