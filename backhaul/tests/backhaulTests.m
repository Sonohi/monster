classdef backhaulTests < matlab.unittest.TestCase
  
  properties
    Config;
    Logger;
    Simulation;
  end
  
  methods (TestMethodSetup)
    function setupObjects(testCase)
      %setup
      testCase.Config = MonsterConfig;
      testCase.Config.Backhaul.backhaulOn = 1;
      testCase.Config.Backhaul.propagationSpeed = 2*10^8; % [m/s] (usual speed of light in a fiber optic cable is approx. 2*10^8 m/s)
      testCase.Config.Backhaul.lengthOfMedium = 1000; % [m]
      testCase.Config.Backhaul.bandwidth = 10^9; % [bps]
      testCase.Config.Backhaul.utilizationLimit = 0.8; %A value of 1 gives 100% of the medium can be used for dataplane traffic.
      testCase.Config.Backhaul.switchDelay = 10^(-4); %[ms]
      testCase.Config.Backhaul.errorRate = 0;
      testCase.Config.Ue.number = 1;
      testCase.Config.Traffic.primary = 'fullBuffer';
      testCase.Config.Traffic.secondary = 'videoStreaming';
      testCase.Config.Traffic.arrivalDistribution = 'Static';
      testCase.Config.Traffic.mix = 0;
      testCase.Config.Traffic.static = 0;
      testCase.Config.SimulationPlot.runtimePlot = 0;
      testCase.Config.Runtime.totalRounds = 100;
      testCase.Logger = MonsterLog(testCase.Config);
      
    end
  end
  
  methods (Test)
    
    function testBackhaulOn(testCase)
      %turn off backhaul
      testCase.Config.Backhaul.backhaulOn = 0;      
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      %Arrivaltime should now be 0 and the first data should be 1e+07
      testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(1,1) == 0);
      testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(1,2) == 1e+07);
      %Trafficsource and TrafficSourceNoBackhaul should be identical
      arrayfun(@(x,y) testCase.verifyTrue(x==y),...
        testCase.Simulation.Traffic.TrafficSourceNoBackhaul(:,1),...
        testCase.Simulation.Traffic.TrafficSource(:,1));
      arrayfun(@(x,y) testCase.verifyTrue(x==y),...
        testCase.Simulation.Traffic.TrafficSourceNoBackhaul(:,2),...
        testCase.Simulation.Traffic.TrafficSource(:,2));
    end
    
    function testDelay(testCase)
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      %First arrival is expected to be after 1ms
      testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(1,1)>10^(-3));
      %Last arrival time is expected to be larger than the number of
      %round in ms
      testCase.verifyTrue(testCase.Simulation.Traffic.TrafficSource(end,1) > (testCase.Config.Runtime.totalRounds-1)*10^(-3))
      %Verify that no traffic is lost
      testCase.verifyTrue(sum(testCase.Simulation.Traffic.TrafficSource(:,2)) == 1e+07);
      %Verify that the Trafficsource and Trafficsource with no backhaul are not equal
      nRounds= testCase.Simulation.Config.Runtime.totalRounds;
      arrayfun(@(x,y) testCase.verifyTrue(x~=y),...
      testCase.Simulation.Traffic.TrafficSourceNoBackhaul(1:nRounds,1),...
      testCase.Simulation.Traffic.TrafficSource(1:nRounds,1));
      arrayfun(@(x,y) testCase.verifyTrue(x~=y),...
      testCase.Simulation.Traffic.TrafficSourceNoBackhaul(1:nRounds,2),...
      testCase.Simulation.Traffic.TrafficSource(1:nRounds,2));
    end
    
    function testMultiUes(testCase)
      %Setup to test functionality for multiple Ues
      testCase.Config.Ue.number = 10;
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      
      %Verify correctness
      %Number of traffic sources and Ues should be the same
      testCase.verifyTrue(length(testCase.Simulation.Traffic)== testCase.Config.Ue.number);
      %verify that the Trafficsource is assigned properly
      arrayfun(@(x,y) testCase.verifyTrue(x.AssociatedUeIds==y), testCase.Simulation.Traffic, 1:testCase.Simulation.Config.Ue.number);
    end
    
    function testTrafficSplit(testCase)
      %Setup to test functionality for multiple Ues
      testCase.Config.Ue.number = 2;
      testCase.Config.Traffic.mix = 0.5;
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      
      %Verify correctness
      %Data should be different for the 1st timeslot
      testCase.verifyTrue(testCase.Simulation.Traffic(1).TrafficSource(1,2) ~= testCase.Simulation.Traffic(2).TrafficSource(1,2));
      %The video user should be done at the 2nd timeslot
      testCase.verifyTrue(0 == testCase.Simulation.Traffic(2).TrafficSource(2,2));
      %The fullbuffer user should be transmitting the same
      testCase.verifyTrue(testCase.Simulation.Traffic(1).TrafficSource(1,2) == testCase.Simulation.Traffic(1).TrafficSource(2,2));
    end
    
    function testError(testCase)
      %Setup to test functionality for error
      testCase.Config.Backhaul.errorRate = 1; %Only errors
      testCase.Config.Backhaul.errorMagnitude = 1; %Remove all data
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      
      %Verify correctness
      %No data should be present
      arrayfun(@(x) testCase.verifyTrue(x == 0), testCase.Simulation.Traffic(1).TrafficSource(:,2));
    end
    
    function testErrorRate(testCase)
      %Setup to test functionality for error
      testCase.Config.Backhaul.errorRate = 0.5; %Half erros
      testCase.Config.Backhaul.errorMagnitude = 1; %Remove all data at errors
      testCase.Config.Runtime.totalRounds = 10000; %Add enough rounds to stabalize result
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      
      %Verify correctness
      %Half data should be present plus/minus 5 percent
      testCase.verifyTrue(sum(testCase.Simulation.Traffic(1).TrafficSource(:,2))*2 > 95e+07 &&...
        sum(testCase.Simulation.Traffic(1).TrafficSource(:,2))*2 < 1.05e+09);
    end
    
    function testErrorMagnitude(testCase)
      %Setup to test functionality for error
      testCase.Config.Backhaul.errorRate = 1; %Only errors
      testCase.Config.Backhaul.errorMagnitude = 0.5; %half all data
      %Apply backhaul
      testCase.Simulation = Monster(testCase.Config, testCase.Logger);
      
      %Verify correctness
      %Half data should be present
      testCase.verifyTrue(sum(testCase.Simulation.Traffic(1).TrafficSource(:,2))*2 == 10000000);
    end
    
  end
  
  
end