classdef enbReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config
		Logger;
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
			testCase.Monster.setupUeTransmitters();
			testCase.Monster.uplinkTraverse();
			
		end
		
	end
	
	methods (Test)
		


		function testChannelEstimation(testCase)

			% Create uplink waveform (with PUSCH)
			testCase.verifyEqual(testCase.Monster.Users(1).Tx.PUSCH.Active,1)

			% Set waveform at enb
			testCase.Monster.Cells.Rx.createReceivedSignal();
				
			% Get users for the given cell
			enbUsers = testCase.Monster.Cells.getUsersScheduledUL(testCase.Monster.Users(1));
			
			% No waveform parsed
			testCase.verifyError(@() testCase.Monster.Cells.Rx.estimateChannels(enbUsers, testCase.Monster.Channel.Estimator), 'MonstereNBReceiverModule:NoWaveformParsed');
			
			% Lets Parse the waveforms and and demodulate it
			testCase.Monster.Cells.Rx.parseWaveform();
			
			testCase.verifyTrue(~isempty(testCase.Monster.Cells.Rx.UeData.Waveform))
				
			% Demodulate received waveforms
			testCase.Monster.Cells.Rx.demodulateWaveforms(enbUsers);
			testCase.verifyTrue(~isempty(testCase.Monster.Cells.Rx.UeData.Subframe))
			
			% Estimate channels
			testCase.Monster.Cells.Rx.estimateChannels(enbUsers, testCase.Monster.Channel.Estimator.Uplink);
			testCase.verifyTrue(~isempty(testCase.Monster.Cells.Rx.UeData.EstChannelGrid));
			testCase.verifyTrue(~isempty(testCase.Monster.Cells.Rx.UeData.NoiseEst));
			
		end

		function testReceivedSignals(testCase)
			
			testCase.verifyTrue(isempty(testCase.Monster.Cells.Rx.Waveforms));
			testCase.Monster.Cells.Rx.createReceivedSignal();
			testCase.verifyTrue(~isempty(testCase.Monster.Cells.Rx.Waveforms));
			
			

		end
		
	end


end