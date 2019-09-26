classdef enbTransmitterModuleTest < matlab.unittest.TestCase

	properties
		Config;
		TxModule;
		Cells;
		Logger;
		Layout;
	end

	methods (TestClassSetup)
		function createTransmitters(testCase)
			testCase.Config  = MonsterConfig();
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Layout = setupNetworkLayout(testCase.Config, testCase.Logger);
			Sites = setupSites(testCase.Config, testCase.Logger, testCase.Layout);
			testCase.Cells = [Sites.Cells];
			testCase.TxModule = [testCase.Cells.Tx];

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
		
		function testCellAssignment(testCase)
			for iCell = 1:length(testCase.Cells)
				testCase.verifyTrue(isa(testCase.Cells(iCell).Tx,'enbTransmitterModule'));
			end
		end
		
		function testCellParameters(testCase)
			for iCell = 1:length(testCase.Cells)
				testCase.verifyTrue(testCase.TxModule(iCell).Enb == testCase.Cells(iCell));
				testCase.verifyTrue(testCase.TxModule(iCell).TxPwdBm == 10*log10(testCase.Cells(iCell).Pmax)+30);
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