classdef enbReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config
		Logger;
		Channel;
		Monster;
		MonsterNoSRS;
	end

	methods (TestClassSetup)
		function setupObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.Mimo.transmissionMode = "Port0";
			testCase.Config.Mimo.elementsPerPanel = [1, 1];
			testCase.Config.MacroEnb.sitesNumber = 1;
			testCase.Config.MacroEnb.cellsPerSite = 1;
			testCase.Config.MicroEnb.sitesNumber = 0;
			testCase.Config.Ue.number = 1;
			testCase.Config.SimulationPlot.runtimePlot = 0;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Monster = Monster(testCase.Config, testCase.Logger);
			
			% Testcase with no SRS
			testCase.Config.SRS.active = false;
			testCase.MonsterNoSRS = Monster(testCase.Config, testCase.Logger);
		end
	end

	methods(TestMethodTeardown)
		function resetObjects(testCase)
			testCase.Monster.clean();
			testCase.MonsterNoSRS.clean();
		end
	end

	methods(TestMethodSetup)
		function setUplinkWaveform(testCase)
			testCase.Monster.associateUsers();
			testCase.Monster.Cells.Mac.ShouldSchedule = 1;
			testCase.Monster.scheduleUL();
			testCase.Monster.setupUeTransmitters();
			testCase.Monster.uplinkTraverse();
			testCase.MonsterNoSRS.associateUsers();
			testCase.MonsterNoSRS.Cells.Mac.ShouldSchedule = 1;
			testCase.MonsterNoSRS.scheduleUL();
			testCase.MonsterNoSRS.setupUeTransmitters();
			testCase.MonsterNoSRS.uplinkTraverse();
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
		
		function testChannelEstimationNoSRS(testCase)
			testCase.MonsterNoSRS.Cells.Rx.createReceivedSignal();
			testCase.MonsterNoSRS.Cells.Rx.parseWaveform();
			enbUsers = testCase.MonsterNoSRS.Users;
			testCase.MonsterNoSRS.Cells.Rx.demodulateWaveforms(enbUsers);
			testCase.MonsterNoSRS.Cells.Rx.estimateChannels(enbUsers, testCase.Monster.Channel.Estimator.Uplink);
			testCase.verifyTrue(~isempty(testCase.MonsterNoSRS.Cells.Rx.UeData.EstChannelGrid));
			testCase.verifyTrue(isempty(testCase.MonsterNoSRS.Users.Tx.Ref.srsIdx));
		end
	end
end