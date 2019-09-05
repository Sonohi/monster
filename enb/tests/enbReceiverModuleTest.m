classdef enbReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config
		Logger;
		Cells;
		Users;
		Channel;
		Monster;
	end

	methods (TestClassSetup)
		function setupObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.MacroEnb.sitesNumber = 1;
			testCase.Config.MacroEnb.cellsPerSite = 1;
			testCase.Config.MicroEnb.sitesNumber = 0;
			testCase.Config.Ue.number = 1;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Monster = Monster(testCase.Config, testCase.Logger);
				
		end
	end

	methods(TestMethodTeardown)
		function resetObjects(testCase)
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

		function testChannelEstimation(testCase)

			% Create uplink waveform (with PUSCH)

			% Set waveform at enb

			% estimate channel, verify that the reference grid is used for additional information

		end

		
	end


end