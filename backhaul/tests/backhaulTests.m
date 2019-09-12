classdef backhaulTests < matlab.unittest.TestCase
    
    properties
       Config;
       Logger;
       Simulation;
    end

    methods (TestClassSetup)
        function setupObjects(testCase)
            %setup
            testCase.Config = MonsterConfig;
            %testCase.Logger = MonsterLog(testCase.Config);
            %testCase.Simulation = Monster(testCase.Config, testCase.Logger);
        end
    end

    methods (Test)

        function testDelay(testCase)
            testCase.Config = MonsterConfig;
            %Setup to test that a delay is applied
            testCase.Config.Backhaul.propagationSpeed = 2*10^8; % [m/s] (usual speed of light in a fiber optic cable is approx. 2*10^8 m/s)
            testCase.Config.Backhaul.lengthOfMedium = 1000; % [m]
            testCase.Config.Backhaul.bandwidth = 10^9; % [bps] 
            testCase.Config.Backhaul.utilizationLimit = 0.8; %A value of 1 gives 100% of the medium can be used for dataplane traffic.
            testCase.Config.Backhaul.switchDelay = 10^(-4); %[ms]
            testCase.Config.Backhaul.errorRate = 0;
            testCase.Config.Ue.number = 1;
            testCase.Config.Traffic.primary = 'fullBuffer';
            testCase.Config.Traffic.arrivalDistribution = 'Static';
            testCase.Config.Traffic.mix = 0;
            testCase.Config.Traffic.static = 0;
            testCase.Config.Runtime.totalRounds = 100;
            testCase.Logger = MonsterLog(testCase.Config);
            %Apply backhaul
            testCase.Simulation = Monster(testCase.Config, testCase.Logger);
            
            %Verify correctness
            %First arrival is expected to be after 1ms
            testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(1,1)>10^(-3));
            %Last arrival time is expected to be larger than the number of
            %round in ms
            testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(end,1) > (testCase.Config.Runtime.totalRounds-1)*10^(-3))
            %Verify that no traffic is lost
            testCase.verifyTrue(sum(testCase.Simulation.Traffic.TrafficSource(:,2)) == 10000000);
            
        end

    end


end