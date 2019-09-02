%% Test Class Definition
classdef ChannelAPITest < matlab.unittest.TestCase


		properties
			Channel
			ChannelModel
			ChannelNoSF
			ChannelNoSFModel
			ChannelNoInterference
			Config
			Cells
			Users
			SFplot
			SINRplot
			Logger
		end

		methods (TestClassSetup)
		
			function createChannel(testCase)

				Config = MonsterConfig();
				Config.SimulationPlot.runtimePlot = 0;
				Config.MacroEnb.number = 5;
				Config.Ue.number = 5;
				Config.Terrain.type = 'city';
				Config.Mobility.scenario = 'pedestrian';
				Config.Channel.shadowingActive = 1;
				testCase.Logger = MonsterLog(Config);
				
				Config.setupNetworkLayout(testCase.Logger);
				Sites = setupSites(Config, testCase.Logger);
				Cells = [Sites.Cells];
				Users = setupUsers(Config, testCase.Logger);
				Channel = setupChannel(Cells, Users, Config, testCase.Logger);
				[Traffic, Users] = setupTraffic(Users, Config, testCase.Logger);
				
				testCase.Config = Config;
				testCase.Cells = Cells;
				testCase.Users = Users;
				testCase.Channel = MonsterChannel(Cells, Users, Config, testCase.Logger);
				testCase.ChannelModel = testCase.Channel.ChannelModel;
				%testCase.SFplot = testCase.ChannelModel.plotSFMap(Cells(1));
				%testCase.SINRplot = testCase.Channel.plotSINR(testCase.Cells, testCase.Users(1), 30, Logger);
				
				
				% Channel with no shadowing
				noShadowingConfig = copy(Config);
				noShadowingConfig.Channel.shadowingActive = 0;
				noShadowingConfig.Channel.losMethod = 'NLOS';
				testCase.ChannelNoSF = MonsterChannel(Cells, Users, noShadowingConfig, testCase.Logger);
				testCase.ChannelNoSFModel = testCase.ChannelNoSF.ChannelModel;
				%testCase.SINRplot = testCase.ChannelNoSF.plotSINR(testCase.Cells, testCase.Users(1), 30, Logger);

				% Channel with no interference
				noInterferenceConfig = copy(Config);
				noInterferenceConfig.Channel.interferenceType = 'None';
				%Param.channel.enableShadowing = 1;
				%Param.channel.InterferenceType = 'None';
				testCase.ChannelNoInterference = MonsterChannel(Cells, Users, noInterferenceConfig, testCase.Logger);

			end
			
			

		end
		
		methods (TestClassTeardown)
		
			function closePlots(testCase)
				close(testCase.SFplot)
				%close(testCase.SINRplot)
			end

		end
		
		methods (TestMethodTeardown)
			
			function resetUserRx(testCase)
				for iUser = 1:length(testCase.Users)
					testCase.Users(iUser).reset();
				end
			end
			
		end
    
    %% Test Method Block
    methods (Test)
        
        %% Test Function
        function testConstructor(testCase)
            testCase.verifyTrue(isa(testCase.Channel,'MonsterChannel'))
				end

				function testChannelModel(testCase)
						testCase.verifyTrue(isa(testCase.ChannelModel,'Monster3GPP38901'))
				end
				
				function testSetup3GPPCellConfigs(testCase)
					testCase.verifyTrue(~isempty(testCase.ChannelModel.CellConfigs))
					testCase.verifyEqual(length(fieldnames(testCase.ChannelModel.CellConfigs)),length(testCase.Cells))
				end

				function test3GPPCellConfigs(testCase)
					for iCell = 1:length(testCase.Cells)
						Cell = testCase.Cells(iCell);
						config = testCase.ChannelModel.findCellConfig(Cell);
						testCase.verifyTrue(~isempty(config.Position))
						testCase.verifyTrue(isa(config.Tx,'enbTransmitterModule'))
						testCase.verifyTrue(isa(config.SpatialMaps, 'struct'))
						testCase.verifyTrue(isa(config.LSP, 'struct'))
						testCase.verifyTrue(isa(config.Seed, 'double'))
						testCase.verifyTrue(all(isfield(config.LSP, {'sigmaSFLOS', 'sigmaSFNLOS', 'dCorrLOS', 'dCorrNLOS', 'dCorrLOSprop'})))
					end
				end

				function test3GPPSpatialMaps(testCase)
					for iCell = 1:length(testCase.Cells)
						Cell = testCase.Cells(iCell);
						config = testCase.ChannelModel.findCellConfig(Cell);
						testCase.verifyTrue(isfield(config.SpatialMaps, 'LOS'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'axisLOS'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'NLOS'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'axisNLOS'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'LOSprop'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'axisLOSprop'))
						testCase.verifyTrue(isa(config.SpatialMaps.LOS, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.axisLOS, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.NLOS, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.axisNLOS, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.LOSprop, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.axisLOSprop, 'double'))
					end
				end

				function test3GPPSpatialMapsNoSF(testCase)
					for iCell = 1:length(testCase.Cells)
						Cell = testCase.Cells(iCell);
						config = testCase.ChannelNoSFModel.findCellConfig(Cell);
						testCase.verifyTrue(~isfield(config.SpatialMaps, 'LOS'))
						testCase.verifyTrue(~isfield(config.SpatialMaps, 'axisLOS'))
						testCase.verifyTrue(~isfield(config.SpatialMaps, 'NLOS'))
						testCase.verifyTrue(~isfield(config.SpatialMaps, 'axisNLOS'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'LOSprop'))
						testCase.verifyTrue(isfield(config.SpatialMaps, 'axisLOSprop'))
						testCase.verifyTrue(isa(config.SpatialMaps.LOSprop, 'double'))
						testCase.verifyTrue(isa(config.SpatialMaps.axisLOSprop, 'double'))
					end
				end

				function testTraverseValidator(testCase)
					testCase.verifyError(@() testCase.Channel.traverse(testCase.Cells, testCase.Users, ''),'MonsterChannel:noChannelMode')
					testCase.verifyError(@() testCase.Channel.traverse(testCase.Cells, [], 'downlink'),'MonsterChannel:WrongUserClass')	
					testCase.verifyError(@() testCase.Channel.traverse([], [], 'downlink'),'MonsterChannel:WrongCellClass')
					
					% No users assigned
					testCase.verifyError(@() testCase.Channel.traverse(testCase.Cells, testCase.Users, 'downlink'),'MonsterChannel:NoUsersAssigned')					
				end

				function testTraverseDownlink(testCase)

					% Assign user
					testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
					testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;
					
					testCase.Cells(1).Tx.Waveform = [];
					testCase.Cells(1).Tx.WaveformInfo = [];

					% Traverse channel downlink with no waveform assigned to
					% transmitter
					testCase.verifyError(@() 	testCase.Channel.traverse(testCase.Cells, testCase.Users, 'downlink'),'MonsterChannel:EmptyTxWaveform')
					
					% Assign waveform and waveinfo to tx module
					testCase.Cells(1).Tx.createReferenceSubframe();
					testCase.Cells(1).Tx.assignReferenceSubframe();
					testCase.Channel.traverse(testCase.Cells, testCase.Users, 'downlink')
					
					% Check that the linkConditions are stored
					testCase.verifyTrue(~isempty(testCase.Channel.ChannelModel.LinkConditions.downlink))

					% Check the assigned user have a received waveform
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.Waveform))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.WaveformInfo))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.SNR))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.RxPwdBm))
					
					if testCase.Channel.enableFading
						testCase.verifyTrue(~isempty(testCase.Users(1).Rx.PathGains))
						testCase.verifyTrue(~isempty(testCase.Users(1).Rx.PathFilters))
					end
	
					% Only one user assigned, thus SINR is equal to SNR
					testCase.verifyTrue((testCase.Users(1).Rx.SINR - testCase.Users(1).Rx.SNR) < 1e-12)
					testCase.verifyTrue((testCase.Users(1).Rx.SINRdB - testCase.Users(1).Rx.SNRdB) < 1e-12)
					
					% Check the other users have nothing
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.Waveform))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.WaveformInfo))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.SNR))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.RxPwdBm))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.SINR))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.PathGains))
					testCase.verifyTrue(isempty(testCase.Users(2).Rx.PathFilters))
				
				end
				
			   function testTraverseUplink(testCase)

					% Assign user and schedule user
					testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
					testCase.Cells(1).setScheduleUL(testCase.Config);
					testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;

					% Traverse channel downlink with no waveform assigned to
					% transmitter
					testCase.verifyError(@() 	testCase.Channel.traverse(testCase.Cells, testCase.Users, 'uplink'),'MonsterChannel:EmptyTxWaveform')
					
					% Assign waveform and waveinfo to tx module
					% Uplink
					testCase.Users(1).Scheduled.UL = 1;
					testCase.Users(1).Tx.setupTransmission();
					testCase.Cells(1).setScheduleUL(testCase.Config);
					
					testCase.Channel.traverse(testCase.Cells, testCase.Users, 'uplink')
					% Check that the linkConditions are stored
					testCase.verifyTrue(~isempty(testCase.Channel.ChannelModel.LinkConditions.uplink{1,1}))
					

					% Check the assigned Cell of the user have a received waveform
					testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.Waveform))
					testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.WaveformInfo))
					testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.SNR))
					testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.RxPwdBm))
					if testCase.Channel.enableFading
						testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.PathGains))
						testCase.verifyTrue(~isempty(testCase.Cells(1).Rx.ReceivedSignals{1}.PathFilters))
					end
					testCase.verifyTrue(isempty(testCase.Cells(1).Rx.ReceivedSignals{2}))
					

					
					% Combine received signals into one final waveform.
					testCase.Cells(1).Rx.createReceivedSignal();
					% Final waveform is the waveform the only user in uplink with the
					% received power set.
					testCase.verifyEqual(testCase.Cells(1).Rx.Waveform, setPower(testCase.Cells(1).Rx.ReceivedSignals{1}.Waveform, testCase.Cells(1).Rx.ReceivedSignals{1}.RxPwdBm))

				 end
				
				 function testOneCellCase(testCase)
					% Assign user
					testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
					testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;
					
					% Assign waveform and waveinfo to tx module
					testCase.Cells(1).Tx.createReferenceSubframe();
					testCase.Cells(1).Tx.assignReferenceSubframe();
					
					testCase.Channel.traverse(testCase.Cells(1), testCase.Users, 'downlink')
					testCase.verifyEqual(round(testCase.Users(1).Rx.SINR,2), round(testCase.Users(1).Rx.SNR,2))
					testCase.verifyEqual(round(testCase.Users(1).Rx.SINRdB,2), round(testCase.Users(1).Rx.SNRdB,2))
					
					
				 end
				

				function testNoInterference(testCase)
					% Assign user
					testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
					testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;

					% Assign waveform and waveinfo to tx module
					testCase.Cells(1).Tx.createReferenceSubframe();
					testCase.Cells(1).Tx.assignReferenceSubframe();
					testCase.ChannelNoInterference.traverse(testCase.Cells, testCase.Users, 'downlink')

					% Check the assigned user have a received waveform and that SNR equals SINR
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.Waveform))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.WaveformInfo))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.SNR))
					testCase.verifyTrue(~isempty(testCase.Users(1).Rx.RxPwdBm))
					
					testCase.verifyEqual(testCase.Users(1).Rx.SINR, testCase.Users(1).Rx.SNR)
					testCase.verifyEqual(testCase.Users(1).Rx.SINRdB, testCase.Users(1).Rx.SNRdB)
				
				
				end
				
				function testDownlinkAndUplink(testCase)
					% Assign user
					testCase.Cells(1).Users = struct('UeId', testCase.Users(1).NCellID, 'CQI', -1, 'RSSI', -1);
					testCase.Users(1).ENodeBID = testCase.Cells(1).NCellID;
					
					testCase.Cells(1).Tx.createReferenceSubframe();
					testCase.Cells(1).Tx.assignReferenceSubframe();
					testCase.Channel.traverse(testCase.Cells, testCase.Users, 'downlink')
					
					% Assign waveform and waveinfo to tx module
					% Uplink
					testCase.Users(1).Scheduled.UL = 1;
					testCase.Users(1).Tx.setupTransmission();
					testCase.Cells(1).setScheduleUL(testCase.Config);
					testCase.Channel.traverse(testCase.Cells, testCase.Users, 'uplink')
					
					testCase.verifyTrue(~isempty(testCase.Channel.ChannelModel.LinkConditions.downlink{1,1}))
					testCase.verifyTrue(~isempty(testCase.Channel.ChannelModel.LinkConditions.uplink{1,1}))
					
				end
				
				
		end
end