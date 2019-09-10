classdef schedulerTest < matlab.unittest.TestCase

	properties
		Monster;
		BaseScheduler;
	end

	methods (TestClassSetup)
		function create(testCase)
			Config  = MonsterConfig();
			Config.SimulationPlot.runtimePlot = 0;
			Config.MacroEnb.number = 1;
			Config.MicroEnb.number = 0;
			Config.Ue.number = 2;
			Logger = MonsterLog(Config);
			testCase.Monster = Monster(Config, Logger);
			testCase.BaseScheduler = Scheduler(testCase.Monster.Cells(1), testCase.Monster.Logger, testCase.Monster.Config);
			
		end
	end

	methods(TestMethodTeardown)
		function reset(testCase)
			testCase.Monster.clean();
		end
	end
	
	methods (Test)

		function testSchedulerConstruction(testCase)
			
			% Not the correct parent object (e.g. eNB)
			testCase.verifyError(@() Scheduler([], testCase.Monster.Logger, testCase.Monster.Config),'Scheduler:NotEvolvedNodeB')
		
			scheduler = Scheduler(testCase.Monster.Cells(1), testCase.Monster.Logger, testCase.Monster.Config);
			testCase.verifyTrue(isa(scheduler,'Scheduler'));
		end
		
		function testAddUsers(testCase)
			% Test that the scheduler keeps a list of scheduled users that
			% corresponds to the Associated users.
			testCase.verifyTrue(isempty(testCase.BaseScheduler.ScheduledUsers));
			
			% Associate user with the cell
			testCase.Monster.Cells(1).associateUser(testCase.Monster.Users(1));
			
			% Check that the base scheduler is empty
			testCase.verifyTrue(isempty(testCase.BaseScheduler.ScheduledUsers));
			testCase.verifyTrue(~isempty(testCase.Monster.Cells(1).AssociatedUsers));
			
			% Update the users of the scheduler
			testCase.BaseScheduler.updateUsers(); 
			
			% Check that the update happened.
			testCase.verifyTrue(~isempty(testCase.BaseScheduler.ScheduledUsers));
			testCase.verifyEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			
			% Associate new user
			testCase.Monster.Cells(1).associateUser(testCase.Monster.Users(2));
			
			% Check that the scheduled users and the basescheduler are no longer
			% synchronized.
			testCase.verifyNotEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			
			% Update the list of the base scheduler.
			testCase.BaseScheduler.updateUsers(); 
			testCase.verifyEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			
			
		end
		
		function testRemoveUser(testCase)
			% Associate 1 user
			testCase.Monster.Cells(1).associateUser(testCase.Monster.Users(1));
			testCase.BaseScheduler.updateUsers();
			testCase.verifyTrue(~isempty(testCase.BaseScheduler.ScheduledUsers));
			testCase.verifyEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			
			% Associate 1 more user, and remove the first
			testCase.Monster.Cells(1).associateUser(testCase.Monster.Users(2));
			testCase.Monster.Cells(1).deassociateUser(testCase.Monster.Users(1));
			testCase.verifyNotEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			testCase.BaseScheduler.updateUsers();
			testCase.verifyEqual(testCase.BaseScheduler.ScheduledUsers, testCase.Monster.Cells(1).AssociatedUsers);
			
			
		end
		
	end


end