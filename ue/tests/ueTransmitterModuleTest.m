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
			
			
		end
		
		function testPUUSCHConfiguration(testCase)
			
		end
		
		
		
	end
	
	
end