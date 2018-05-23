classdef MMobility < handle
	%MMOBILITY Summary of this class goes here
	% Directions defined as:
	%       1
	%   *--------*
	%   *        *
	% 2 *        * 4
	%   *        *
	%   *--------*
	%       3
	
	properties
		Scenario;
		Velocity;
		Seed;
		Rounds;
		Trajectory = [];
		TimeStep = 1e-3;
	end
	
	properties (Access = private)
		roadWidth;
		laneWidth;
		wallDistance;
		pedestrianDistance;
		pedestrianTurnPause;
		pedestrianCrossingPause;
		buildingFootprints;
		movementSpeed;
		distanceMoved;
		eastwest = [2, 4];
		northsouth = [1, 3];
		timeLeftForCrossing;
		timeLeftForTurning;
		currentBuilding;
	end

	methods
		function obj = MMobility(scenario, velocity, seed, rounds, Param)
			% Validate scenario
			if ~strcmp(scenario, 'pedestrian')
				sonohilog('Mobility scenario not supported','ERR')
			end
			
			% Set arguments
			obj.Scenario = scenario;
			obj.Velocity = velocity;
			obj.Seed = seed;
			obj.Rounds = rounds;
			obj.buildingFootprints = Param.buildings;
			
			% Produce parameters and compute movement.
			obj.setParameters();
			obj.createTrajectory();
		end
	end

	methods (Access = private)

		function obj = createTrajectory(obj)
				% Create vector of trajectory with length(rounds)
				obj.Trajectory = zeros(obj.Rounds, 2); % x and y
				if strcmp(obj.Scenario, 'pedestrian')
					obj.randomWalkPedestrian();
				end
		end
		
		function obj = randomWalkPedestrian(obj)
			% Computes a trajectory with pedestrian type movement
			% starting point and destination
			rng(obj.Seed);
			[start, startSide] = obj.getRandomBuilding();
			%[stop, stopSide] = obj.getRandomBuilding();

			startPos = zeros(1,2);
			%stopPos = zeros(1,2);
			[startPos(1), startPos(2)] = obj.getExitPoint(start, startSide);
			%[stopPos(1), stopPos(2)] = obj.getExitPoint(stop, stopSide);

			% Add starting position to trajectory
			obj.Trajectory(1,:) = startPos;

			% Given the starting side, chose a random direction
			% e.g. if starting side of the building is north or south, user can only
			% move west or east.
			direction = obj.getMovementDirection(startSide);
			sonohilog(sprintf('Moving in direction %i',direction))
			obj.currentBuilding = obj.buildingFootprints(start,:);
			side = startSide;
			state = 'moving';
			for round = 2:obj.Rounds
				
					% Check state
					switch state
						case 'moving'
							% Reset state variables
							turnOrCross = false;
							turn = false;
							cross = false;
							
							oldPos = obj.Trajectory(round-1,:);
							newPos = obj.movement(oldPos, direction);
							turnOrCross = obj.checkTurnOrCross(newPos, direction);
							if turnOrCross
								[turn, cross, directionNew] = obj.decideTurnOrCross(direction, side);
								
								if turn
									obj.Trajectory(round,:) = oldPos;
									state = 'turning';
								elseif cross
									obj.Trajectory(round,:) = oldPos;
									state = 'crossing';
								end
							else
								obj.Trajectory(round,:) = newPos;
							end
						case 'turning'
							obj.timeLeftForTurning = obj.timeLeftForTurning - obj.TimeStep;
							if obj.timeLeftForTurning <= 0
								direction = directionNew;
								state = 'moving';
								oldPos = obj.Trajectory(round-1,:);
								newPos = obj.movement(oldPos, direction);
								
								obj.Trajectory(round,:) = newPos;
							else
								obj.Trajectory(round,:) = oldPos;
							end
						case 'crossing'
							obj.timeLeftForCrossing = obj.timeLeftForCrossing - obj.TimeStep;
							if obj.timeLeftForCrossing <= 0
								% move and cross, 
								% When moved across road, update obj.currentBuilding  
								state = 'moving';
							else
								obj.Trajectory(round,:) = oldPos;
							end

					end
					% Check if new position exeeds the building moved next to
					% this means the user needs to decide wether turn or cross
					
					
					
					
% 					
% 					if ~waiting
% 						[turnOrCross, building] = obj.checkTurnOrCross(newPos, direction, building, round);
% 						if turnOrCross
% 							waiting = true;
% 							[turn, cross, directionNew] = obj.decideTurnOrCross(side);
% 							% If we're moving along side 1 of the bulding (thus moving either west or east), and the new
% 							% direction is south, we execute a turn. Otherwise we cross
% 							if turn
% 								obj.timeLeftForTurning = obj.timeLeftForTurning - obj.TimeStep;
% 							elseif cross
% 								obj.timeLeftForCrossing = obj.timeLeftForCrossing - obj.TimeStep;
% 							end
% 							obj.Trajectory(round,:) = oldPos;
% 							
% 						else 
% 							obj.Trajectory(round,:) = newPos;
% 						end
% 					
% 					if obj.timeLeftForTurning == 0 || obj.timeLeftForCrossing == 0
% 							% This means waiting time is over, and we can either cross or
% 							% turn, anyhow we update direction to the new direction
% 							direction = directionNew;
% 							waiting = false;
% 					end
				
			end
		end
		
		function obj = setParameters(obj)
			obj.roadWidth = 9;
			obj.laneWidth = obj.roadWidth / 3;
			obj.wallDistance = 1;
			if strcmp(obj.Scenario, 'pedestrian')
				obj.pedestrianDistance = 0.5;
				obj.pedestrianTurnPause = 0.02 % 20 ms of pause;
				obj.pedestrianCrossingPause = 5; % Roughly 5 seconds for crossing, equal to 5000 rounds
				obj.timeLeftForCrossing = obj.pedestrianCrossingPause;
				obj.timeLeftForTurning = obj.pedestrianTurnPause;
				obj.movementSpeed = 1; % [m/s]
			end
			
			obj.distanceMoved = obj.TimeStep * obj.movementSpeed;
		end
		
		function [buildingIdx, buildingSide] = getRandomBuilding(obj)
			buildingIdx = randi(length(obj.buildingFootprints(:, 1)));
			buildingSide = randi(4); %N/W/S/E side of building it intersects
		end
		
		function direction = getMovementDirection(obj, side)
			if any(ismember(obj.northsouth, side))
				direction = obj.eastwest(randi(2));
			else
				direction = obj.northsouth(randi(2));
			end

		end
		
		function [turn, cross, directionNew] = decideTurnOrCross(obj, direction, side)
				% Pick new direction
				directionNew = randi(4);
				turn = false;
				cross = false;
				if side == 1 && directionNew == 3
					turn = true;
				elseif side == 3 && directionNew == 1
					turn = true;
				elseif side == 2 && directionNew == 4
					turn = true;
				elseif side == 4 && directionNew == 2
					turn = true;
				else 
					cross = true;
				end
		end
		
		function [turnOrCross] = checkTurnOrCross(obj, newPos, direction)
				turnOrCross = false;
				if (direction == 1) && (round(newPos(2),5) > round(obj.currentBuilding(4),5))
						turnOrCross = true;
					elseif (direction == 2) && (round(newPos(1),5) < round(obj.currentBuilding(1),5))
						turnOrCross = true;
					elseif (direction == 3) && (round(newPos(2),5) < round(obj.currentBuilding(2),5))
						turnOrCross = true;
					elseif (direction == 4) && (round(newPos(1),5) < round(obj.currentBuilding(3),5))
						turnOrCross = true;
				end
			
		end
		
		function newPos = movement(obj, oldPos, direction)
					 if direction == 1
						% If we move north, only y change
						newPos = [oldPos(1), oldPos(2)+obj.distanceMoved];
					elseif direction == 2
						% if we move west, only x change
						newPos = [oldPos(1)-obj.distanceMoved, oldPos(2)];
					elseif direction == 3
						% If we move south, only y change
						newPos = [oldPos(1), oldPos(2)-obj.distanceMoved];
					else
						% If we move east, only x change
						newPos = [oldPos(1)+obj.distanceMoved, oldPos(2)];
					end
		end
		
		function [x, y] = getExitPoint(obj, building, Side)
			building = obj.buildingFootprints(building, 1:4);
			sides = zeros(4, 4);
			sides(:, 1) = [building(3), building(4),  building(1), building(4)];
			sides(:, 2) = [building(1), building(4),  building(1), building(2)];
			sides(:, 3) = [building(1), building(2),  building(3), building(2)];
			sides(:, 4) = [building(3), building(2),  building(3), building(4)]; 

			% median point of the building side
			x = (sides(1, Side) + sides(3, Side)) / 2;
			y = (sides(2, Side) + sides(4, Side)) / 2;

			% add distance given the chosen side
			if Side == 1
					y = y + obj.wallDistance;
			elseif Side == 2
					x = x - obj.wallDistance;
			elseif Side == 3
					y = y - obj.wallDistance;
			elseif Side == 4
					x = x + obj.wallDistance;
			end
		end


	end


end

