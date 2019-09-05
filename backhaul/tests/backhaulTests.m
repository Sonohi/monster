classdef backhaulTests < matlab.unittest.TestCase
    
    properties
       Config;
       Traffic; 
    end

    methods (TestClassSetup)
        function createSimulationInstance(testCase)
            %setup
            testCase.Config = MonsterConfig;
            testCase.Logger = MonsterLog(testCase.Config);
            testCase.Simulation = Monster(testCase.Config, testCase.Logger);
        end
    end

    methods (Tests)

        function testDelay(testCase)
            %Assert if a delay is applied
            
        end

    end


end