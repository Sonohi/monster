classdef ueReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config;
		TxModule;
		RxModule;
		Stations;
		Channel;
		Users;
	end

	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Config.MacroEnb.number = 1;
			testCase.Config.MicroEnb.number = 0;
			testCase.Config.Ue.number = 1;
			testCase.Config.setupNetworkLayout();
			testCase.Stations = setupStations(testCase.Config);
			testCase.Users = setupUsers(testCase.Config);
			testCase.RxModule = [testCase.Users.Rx];
			testCase.TxModule = [testCase.Stations.Tx];
			testCase.Channel = setupChannel(testCase.Stations, testCase.Users, testCase.Config);
				
		end
	end

	methods(TestMethodTeardown)
		function resetTransmitters(testCase)
			arrayfun(@(x) x.reset(), [testCase.TxModule]);
		end
	end
	
	methods (Test)

		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.RxModule, 'ueReceiverModule'));
		end

		function testDemodulation(testCase)
            
            
			% Schedule user for downlink transmission
			testCase.Stations(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
			testCase.Users(1).ENodeBID = testCase.Stations(1).NCellID;

			testCase.Stations(1).ScheduleDL(1).UeId = testCase.Users(1).NCellID;
			testCase.Stations(1).ScheduleDL(1).Mcs = 4;
            %testCase.Stations(1).evaluateScheduling(testCase.Users);
            %testCase.Stations(1).downlinkSchedule(testCase.Users, testCase.Config);
            
	
			% Setup up reference grid
			testCase.Stations(1).Tx.setupGrid(0);
            %testCase.Stations(1).Tx.setPRBSSequence(ue);

			% Create waveform
			testCase.Stations(1).Tx.modulateTxWaveform();

			
			% Set waveform in Rx module
			testCase.Users(1).Rx.Waveform = testCase.Stations(1).Tx.Waveform;
			testCase.Users(1).Rx.WaveformInfo = testCase.Stations(1).Tx.WaveformInfo;
			testCase.Users(1).Rx.RxPwdBm = -30;
			
			% Demodulate and verify reference signals + data
			testCase.Users(1).Rx.receiveDownlink(testCase.Stations(1), testCase.Channel.Estimator.Downlink)
	
            % Check demodulation is possible
			testCase.verifyTrue(testCase.Users(1).Rx.Demod==1)
			
            % Check the subframes are within reasonable distance of each other
            diffSubframesTxRx = sum(testCase.Users(1).Rx.EqSubframe - testCase.Stations(1).Tx.ReGrid);
            testCase.verifyFalse(any(diffSubframesTxRx > 10e-14))
           
            % Check Tx bits corresponds to Rx bits
            
            
		end
	
		
	end


end