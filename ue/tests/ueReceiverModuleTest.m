classdef ueReceiverModuleTest < matlab.unittest.TestCase

	properties
		Config;
		TxModule;
		RxModule;
		Stations;
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
			% Setup up reference waveform to transmit
			testCase.Stations(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
			testCase.Users(1).ENodeBID = testCase.Stations(1).NCellID;
						
			% Create the transport blocks for all the UEs
			arrayfun(@(x)x.generateTransportBlockDL(testCase.Stations, testCase.Config), testCase.Users);

			% Create the codewords for all the UEs
			arrayfun(@(x)x.generateCodewordDL(), testCase.Users);

			% Setup the reference signals at the eNB transmitters 
			arrayfun(@(x)x.setupGrid(testCase.Config.Runtime.currentRound), [testCase.Stations.Tx]);
			
			
			% Create the symbols for all the UEs' codewords at the eNodeBs
			arrayfun(@(x)x.generateSymbols(testCase.Users), testCase.Stations);

			
			% Finally modulate the waveform for all the eNodeBs
			arrayfun(@(x)x.modulateTxWaveform(), [testCase.Stations.Tx]);

		end
	
		
	end


end