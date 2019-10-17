classdef MetricRecorderTest < matlab.unittest.TestCase
	
	properties
		Config;
		MetricRecorder;
		Cells;
		Users;
		Logger;
	end
	
	methods (TestClassSetup)
		function createObjects(testCase)
			testCase.Config = MonsterConfig();
			%Set Harq active:
			testCase.Config.Harq.active = true;
			testCase.Logger = MonsterLog(testCase.Config);
			testCase.Config.setupNetworkLayout(testCase.Logger);
			Sites = setupSites(testCase.Config, testCase.Logger);
			testCase.Cells = [Sites.Cells];
			testCase.Users = setupUsers(testCase.Config, testCase.Logger);
			testCase.MetricRecorder = setupResults(testCase.Config, testCase.Logger);
		end
	end
	
	methods (Test)
		function testConstructor(testCase)
			testCase.verifyTrue(isa(testCase.MetricRecorder,'MetricRecorder'));
			testCase.verifyTrue(isa(testCase.MetricRecorder.Config,'MonsterConfig'));
			testCase.verifyTrue(testCase.Config == testCase.MetricRecorder.Config);
		end
		
		function testRecordEnbMetrics(testCase)
			testCase.MetricRecorder.recordEnbMetrics(testCase.Cells, testCase.Config, testCase.Logger);
			%TODO: check for range and for all cells
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.util(1)));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.powerConsumed(1,1)));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.schedule(1, 1, 1).UeId));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.schedule(1, 1, 1).MCS));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.schedule(1, 1, 1).ModOrd));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.powerState(1,1)));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.harqRtx(1,1)));
			testCase.verifyTrue(~isnan(testCase.MetricRecorder.arqRtx(1,1)));
		end
		
		function testRecordUeMetrics(testCase)
			testCase.MetricRecorder.recordUeMetrics(testCase.Users, 0);
			%TODO: check for range and for all users
			testCase.verifyTrue(isnan(testCase.MetricRecorder.ber(1,1)));
			testCase.verifyTrue(isnan(testCase.MetricRecorder.bler(1,1)));%Is this even doing anything?!?
			testCase.verifyTrue(testCase.MetricRecorder.snrdB(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.sinrdB(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.cqi(1,1)==3);
			testCase.verifyTrue(testCase.MetricRecorder.preEvm(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.postEvm(1,1)==0);
			testCase.verifyTrue(isnan(testCase.MetricRecorder.throughput(1,1)));
			testCase.verifyTrue(testCase.MetricRecorder.receivedPowerdBm(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.rsrqdB(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.rsrpdBm(1,1)==0);
			testCase.verifyTrue(testCase.MetricRecorder.rssidBm(1,1)==0);
			
		end
	end
end