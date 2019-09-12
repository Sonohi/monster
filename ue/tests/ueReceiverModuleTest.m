classdef ueReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config;
		TxModule;
		RxModule;
		Cells;
		Channel;
		Users;
		Logger;
	end

	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.MacroEnb.sitesNumber = 1;
			testCase.Config.MacroEnb.cellsPerSite = 1;
			testCase.Config.MicroEnb.sitesNumber = 0;
			testCase.Config.Ue.number = 1;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Config.setupNetworkLayout(testCase.Logger);
			Sites = setupSites(testCase.Config, testCase.Logger);
			testCase.Cells = [Sites.Cells];
			testCase.Users = setupUsers(testCase.Config, testCase.Logger);
			testCase.RxModule = [testCase.Users.Rx];
			testCase.TxModule = [testCase.Cells.Tx];
			testCase.Channel = setupChannel(testCase.Cells, testCase.Users, testCase.Config, testCase.Logger);
				
		end
	end

	methods(TestMethodTeardown)
		function resetTransmitters(testCase)
			arrayfun(@(x) x.reset(), [testCase.TxModule]);
			arrayfun(@(x) x.reset(), [testCase.RxModule]);
		end
	end
	
	methods(TestMethodSetup)
		function setDownlinkWaveform(testCase)
					

			% Schedule user for downlink transmission
			testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
			testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;
			
			% Setup transport block downlink
			testCase.Users(1).generateTransportBlockDL(testCase.Cells, testCase.Config);

			% Setup codewords
			testCase.Users(1).generateCodewordDL();

			% Setup up reference grid
			testCase.Cells(1).Tx.setupGrid(0);

			% Create Symbols
			testCase.Cells(1).setupPdsch(testCase.Users);

			% Create waveform
			testCase.Cells(1).Tx.modulateTxWaveform();
			
			% Set waveform in Rx module
			testCase.Users(1).Rx.Waveform = testCase.Cells(1).Tx.Waveform;
			testCase.Users(1).Rx.ChannelConditions.WaveformInfo = testCase.Cells(1).Tx.WaveformInfo;
			testCase.Users(1).Rx.ChannelConditions.RxPwdBm = -30;
			
		end
		
	end
	
	methods (Test)

		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.RxModule, 'ueReceiverModule'));
		end

		function testDemodulation(testCase)			
			% Demodulate and verify reference signals + data
			testCase.Users(1).Rx.demodulateWaveform(testCase.Cells(1));
			testCase.verifyEqual(testCase.Users(1).Rx.Demod,1);
			diffSubframe = sum(abs(testCase.Cells(1).Tx.ReGrid - testCase.Users(1).Rx.Subframe));
			testCase.verifyFalse(any(diffSubframe > 10e-12));
		end
		
		function testDemodulateError(testCase)
			% No waveform set
			testCase.Users(1).Rx.reset();
			testCase.verifyError(@() testCase.Users(1).Rx.demodulateWaveform(testCase.Cells(1)),'MonsterUeReceiverModule:EmptyWaveform');
		end
		
		function testOffsetComputation(testCase)
			% Add some arbitary offset to the waveform
			offset = 15;
			testCase.Users(1).Rx.Waveform = circshift(testCase.Users(1).Rx.Waveform,offset);
			testCase.Users(1).Rx.applyOffset(testCase.Cells(1));
			testCase.verifyEqual(testCase.Users(1).Rx.Offset, offset);
		end
		
		function testChannelEstimator(testCase)

			% No waveform demodulated
			testCase.verifyError(@() testCase.Users(1).Rx.estimateChannel(testCase.Cells(1), testCase.Channel.Estimator.Downlink),'MonsterUeReceiverModule:EmptySubframe')
			
			% Waveform demodulated
			testCase.Users(1).Rx.applyOffset(testCase.Cells(1));
			testCase.Users(1).Rx.demodulateWaveform(testCase.Cells(1))
			testCase.Users(1).Rx.estimateChannel(testCase.Cells(1), testCase.Channel.Estimator.Downlink);
			testCase.verifyTrue(~isempty(testCase.Users(1).Rx.EstChannelGrid));
			testCase.verifyTrue(~isempty(testCase.Users(1).Rx.NoiseEst));
		end

		function testEqualizer(testCase)

			% No subframe available
			testCase.verifyError(@() testCase.Users(1).Rx.equaliseSubframe(),'MonsterUeReceiverModule:EmptySubframe');

			% Demodulate but do not estimate the channel
			testCase.Users(1).Rx.demodulateWaveform(testCase.Cells(1));
			testCase.verifyError(@() testCase.Users(1).Rx.equaliseSubframe(),'MonsterUeReceiverModule:EmptyChannelEstimation');

			% Estimate channel
			testCase.Users(1).Rx.estimateChannel(testCase.Cells(1), testCase.Channel.Estimator.Downlink);
			testCase.Users(1).Rx.equaliseSubframe();
			testCase.verifyTrue(~isempty(testCase.Users(1).Rx.EqSubframe))


		end
		

		
	end


end