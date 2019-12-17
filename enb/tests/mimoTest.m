classdef mimoTest  < matlab.unittest.TestCase

	properties
		Config;
		Cells;
		Logger;
		Monster;
	end

	methods (TestClassSetup)
		function setupTest(testCase)
			testCase.Config = MonsterConfig();
			testCase.Config.SimulationPlot.runtimePlot = 0;
			testCase.Config.Traffic.primary = 'fullBuffer';
			testCase.Config.Traffic.arrivalDistribution = 'Static';
			testCase.Config.Traffic.static = 0;
			testCase.Config.Channel.mode = '3GPP38901';
			testCase.Config.Channel.fadingActive = true;
			testCase.Config.Channel.fadingModel = 'TDL';
			testCase.Config.Mimo.transmissionMode = "TxDiversity";
			testCase.Config.Mimo.elementsPerPanel = [2, 2];
			testCase.Config.MacroEnb.sitesNumber = 1;
			testCase.Config.MacroEnb.cellsPerSite = 1;
			testCase.Config.MicroEnb.sitesNumber = 0;
			testCase.Config.Ue.number = 1;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Monster = Monster(testCase.Config, testCase.Logger);
		end
	end

	methods (TestMethodTeardown)
		function cleanUp(testCase)
			testCase.Monster.clean();
		end
	end

	methods (Test)
		function testConstruction(testCase)
			enbCell = testCase.Monster.Cells(1);
			enbTx = testCase.Monster.Cells(1).Tx;
			ue = testCase.Monster.Users(1);
			ueRx = testCase.Monster.Users(1).Rx;
			arrayTuple = testCase.Monster.Cells(1).Mimo.arrayTuple;
			testCase.verifyTrue(isa(enbCell, 'EvolvedNodeB'));
			testCase.verifyTrue(enbCell.Mimo.numAntennas == testCase.Config.Mimo.elementsPerPanel(1)*testCase.Config.Mimo.elementsPerPanel(2));
			testCase.verifyTrue(strcmp(enbCell.Mimo.txMode, 'TxDiversity'));
			sizeTest = enbTx.AntennaArray.ElementsPerPanel == arrayTuple(3:4);
			testCase.verifyTrue(sum(sizeTest)/length(sizeTest) == 1);
			testCase.verifyTrue(enbTx.AntennaArray.Polarizations == arrayTuple(5));
			testCase.verifyTrue(ue.Mimo.numAntennas == testCase.Config.Mimo.elementsPerPanel(1)*testCase.Config.Mimo.elementsPerPanel(2));
			sizeTest = ueRx.AntennaArray.ElementsPerPanel == arrayTuple(3:4);
			testCase.verifyTrue(sum(sizeTest)/length(sizeTest) == 1);
			testCase.verifyTrue(ueRx.AntennaArray.Polarizations == arrayTuple(5));
		end

		function testWaveforms(testCase)
			% Test waveform sizes for the DL direction
			testCase.Monster.setupRound(0);
			testCase.Monster.run();
			numAntennas = testCase.Config.Mimo.elementsPerPanel(1)*testCase.Config.Mimo.elementsPerPanel(2);
			txWaveforms = testCase.Monster.Cells(1).Tx.Waveform;
			rxWaveforms = testCase.Monster.Users(1).Rx.Waveform;
			testCase.verifyTrue(size(txWaveforms, 2) == numAntennas);
			testCase.verifyTrue(size(rxWaveforms, 2) == numAntennas);
		end
	end
end