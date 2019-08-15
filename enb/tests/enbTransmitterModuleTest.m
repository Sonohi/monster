classdef enbTransmitterModuleTest < matlab.unittest.TestCase

	properties
		Config;
		TxModule;
		Stations;
		Logger;
	end

	methods (TestClassSetup)
		function createTransmitters(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Config.setupNetworkLayout(testCase.Logger);
			Sites = setupSites(testCase.Config, testCase.Logger);
			testCase.Stations = [Sites.Cells];
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
			testCase.verifyTrue(isa(testCase.TxModule, 'enbTransmitterModule'));
		end
		
		function testStationAssignment(testCase)
			for iStation = 1:length(testCase.Stations)
				testCase.verifyTrue(isa(testCase.Stations(iStation).Tx,'enbTransmitterModule'));
			end
		end
		
		function testStationParameters(testCase)
			for iStation = 1:length(testCase.Stations)
				testCase.verifyTrue(testCase.TxModule(iStation).Enb == testCase.Stations(iStation));
				testCase.verifyTrue(testCase.TxModule(iStation).TxPwdBm == 10*log10(testCase.Stations(iStation).Pmax)+30);
			end
		end
		
		function testSetupGrid(testCase)
			arrayfun(@(x) x.setupGrid(1), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(isempty(x.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(isempty(x.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.ReGrid)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.PBCH)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.ReGrid)), testCase.TxModule);
		end
		
		function testCreateReferenceSubframe(testCase)
			arrayfun(@(x) testCase.verifyTrue(isempty(x.Ref.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(isempty(x.Ref.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(isempty(x.Ref.ReGrid)), testCase.TxModule);
			arrayfun(@(x) x.createReferenceSubframe(), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Ref.ReGrid)), testCase.TxModule);
		end
		
		function testAssignReferenceSubframe(testCase)
			arrayfun(@(x) testCase.verifyTrue(isempty(x.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(isempty(x.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) x.createReferenceSubframe(), testCase.TxModule);
			arrayfun(@(x) x.assignReferenceSubframe(), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.Waveform)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.WaveformInfo)), testCase.TxModule);
			arrayfun(@(x) testCase.verifyTrue(~isempty(x.ReGrid)), testCase.TxModule);
		end
		
		function testGetEIRPdBm(testCase)
			TxPosition = [250, 250, 35];
			RxPosition = [250, 350, 1.5];
			arrayfun(@(x) testCase.verifyTrue(isa(x.getEIRPdBm(TxPosition, RxPosition),'double')), testCase.TxModule);
		end
		
	end


end