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
		crossingDistance = 0; %Used to determine if crossing is completed
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
		currentSide;
		currentDirection;
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
		
				
		function plotTrajectory(obj)
			startPos = obj.Trajectory(1,:);
			figure
			h = gca;
			plot(h, startPos(1),startPos(2),'rx')
			hold on
			plot(h, obj.Trajectory(2:end,1),obj.Trajectory(2:end,2),'b-')
			for i = 1:length(obj.buildingFootprints(:,1))
				x0 = obj.buildingFootprints(i,1);
				y0 = obj.buildingFootprints(i,2);
				x = obj.buildingFootprints(i,3)-x0;
				y = obj.buildingFootprints(i,4)-y0;
				rectangle(h, 'Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
			end
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
			obj.currentSide = startSide;
			obj.currentDirection = obj.getMovementDirection();
			obj.currentBuilding = obj.buildingFootprints(start,:);
			next_state = 'moving';
			justTurnedOrCrossed = false;
			turningDistance = 2*obj.wallDistance;
			for round = 2:obj.Rounds
					state = next_state;
					
					% Check state
					switch state
						case 'moving'
							% Reset state variables
							turnOrCross = false;
							turn = false;
							cross = false;
							
							oldPos = obj.Trajectory(round-1,:);
							newPos = obj.movement(oldPos);
							if ~justTurnedOrCrossed
								turnOrCross = obj.checkTurnOrCross(newPos);
							end
							% TODO: check if he's moving beyond boundaries of buildings
							
							if turnOrCross
								[turn, cross] = obj.decideTurnOrCross();
								if turn
									obj.Trajectory(round,:) = oldPos;
									next_state = 'turning';
								elseif cross
									obj.Trajectory(round,:) = oldPos;
									next_state = 'crossing';
								end
							else
								obj.Trajectory(round,:) = newPos;
							end
							justTurnedOrCrossed = false;
							
						case 'turning'
							obj.timeLeftForTurning = obj.timeLeftForTurning - obj.TimeStep;
							if obj.timeLeftForTurning <= 0
								
								
								oldPos = obj.Trajectory(round-1,:);
								newPos = obj.movement(oldPos);
								turningDistance = turningDistance - obj.distanceMoved;
								
								justTurnedOrCrossed = true;
								if turningDistance <= 0
									obj.getBuildingSide(newPos);
									obj.timeLeftForTurning = obj.pedestrianTurnPause;
									turningDistance = 2*obj.wallDistance;
									next_state = 'moving';
								end
								
								obj.Trajectory(round,:) = newPos;
							else
								obj.Trajectory(round,:) = oldPos;
							end
							
						case 'crossing'
							if obj.timeLeftForCrossing > 0
							 obj.timeLeftForCrossing = obj.timeLeftForCrossing - obj.TimeStep;
							 obj.Trajectory(round,:) = oldPos;
							else
								% move and cross, 
								% When moved across road, update obj.currentBuilding
								oldPos = obj.Trajectory(round-1,:);
								newPos = obj.movement(oldPos);
								% Check new pos is across street. (road width - wall
								% width)
								streetIsCrossed = obj.checkStreetIsCrossed();
								obj.Trajectory(round,:) = newPos;
								if streetIsCrossed
										obj.crossingDistance = 0;
										obj.findClosestBuilding(newPos);
										obj.getBuildingSide(newPos);
										% Reset time when crossed
										obj.timeLeftForCrossing = obj.pedestrianCrossingPause;
										obj.crossingDistance = 0;
										justTurnedOrCrossed = true;
										next_state = 'moving';
								end
								
							end

					end
			end
		end
		
		function obj = setParameters(obj)
			obj.roadWidth = 10;
			obj.laneWidth = obj.roadWidth / 3;
			obj.wallDistance = 1;
			if strcmp(obj.Scenario, 'pedestrian')
				obj.pedestrianDistance = 0.5;
				% TODO: randomize wait times between appropriate numbers.
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
		
		function [building] = findClosestBuilding(obj, position)
			% Sort by distance in x direction,
			[leftX, leftXIdx] = sort(floor(abs(obj.buildingFootprints(:,1) - position(1))), 1); % left corner
			[rightX, rightXIdx] = sort(floor(abs(obj.buildingFootprints(:,3) - position(1))), 1); % right corner
			
			% Sort by distance in y direction,
			[topY, topYIdx] = sort(floor(abs(obj.buildingFootprints(:,2) - position(2))), 1); % left corner
			[bottomY, bottomYIdx] = sort(floor(abs(obj.buildingFootprints(:,4) - position(2))), 1); % right corner
			
			% Building with the closest corner equals closest building
			threshold = 3;
			leftXFiltered = leftXIdx(leftX <= threshold);
			rightXFiltered = rightXIdx(rightX <= threshold);
			
			topYFiltered = topYIdx(topY <= threshold);
			bottomYFiltered = bottomYIdx(bottomY <= threshold);
			
			if isempty(leftXFiltered)
				cornerXIdx = rightXFiltered;
			else
				cornerXIdx = leftXFiltered;
			end
			
			if isempty(topYFiltered)
				cornerYIdx = bottomYFiltered;
			else
				cornerYIdx = topYFiltered;
			end
			
			% Closest building must then be thus where these intersect.
			obj.currentBuilding = obj.buildingFootprints(intersect(cornerXIdx, cornerYIdx),:);
			
			if isempty(obj.currentBuilding)
				sonohilog('Something went wrong in finding closest building','ERR')
				
			end
			
		end
		
		function [streetCrossed] = checkStreetIsCrossed(obj)
			
			obj.crossingDistance = obj.crossingDistance + obj.distanceMoved;
			streetCrossed = false;
			if obj.crossingDistance > obj.roadWidth + 2*obj.wallDistance
				streetCrossed = true;
			end
			
		end
		
		function direction = getMovementDirection(obj)
			if any(ismember(obj.northsouth, obj.currentSide))
				direction = obj.eastwest(randi(2));
			else
				direction = obj.northsouth(randi(2));
			end

		end
		
		function getBuildingSide(obj, newPos)
			if round(newPos(1),5) < round(obj.currentBuilding(1),5)
				obj.currentSide = 2;
			elseif round(newPos(1),5) > round(obj.currentBuilding(3),5)
				obj.currentSide = 4;
			elseif round(newPos(2),5) < round(obj.currentBuilding(2),5)
				obj.currentSide = 3;
			elseif round(newPos(2),5) > round(obj.currentBuilding(4),5)
				obj.currentSide = 1;
			end
		end
		
		function [turn, cross] = decideTurnOrCross(obj)
				% Pick new direction, not possible to go back.
				possibledirections = [];
				if any(ismember(obj.northsouth, obj.currentDirection))
					possibledirections = [possibledirections obj.currentDirection];
					possibledirections = [possibledirections obj.eastwest];
				else
					possibledirections = [possibledirections obj.currentDirection];
					possibledirections = [possibledirections obj.northsouth];
				end

				directionNew = possibledirections(randi(length(possibledirections)));
				turn = false;
				cross = false;
				if (obj.currentSide == 1) && (directionNew == 3)
					turn = true;
				elseif (obj.currentSide == 3) && (directionNew == 1)
					turn = true;
				elseif (obj.currentSide == 2) && (directionNew == 4)
					turn = true;
				elseif (obj.currentSide == 4) && (directionNew == 2)
					turn = true;
				else 
					cross = true;
				end
				
				obj.currentDirection = directionNew;
		end
		
		function [turnOrCross] = checkTurnOrCross(obj, newPos)
				turnOrCross = false;
				if (obj.currentDirection == 1) && (round(newPos(2),5) > round(obj.currentBuilding(4),5)+obj.wallDistance)
						turnOrCross = true;
					elseif (obj.currentDirection == 2) && (round(newPos(1),5) < round(obj.currentBuilding(1),5)-obj.wallDistance)
						turnOrCross = true;
					elseif (obj.currentDirection == 3) && (round(newPos(2),5) < round(obj.currentBuilding(2),5)-obj.wallDistance)
						turnOrCross = true;
					elseif (obj.currentDirection == 4) && (round(newPos(1),5) < round(obj.currentBuilding(3),5)+obj.wallDistance)
						turnOrCross = true;
				end
			
		end
		
		function newPos = movement(obj, oldPos)
					 if obj.currentDirection == 1
						% If we move north, only y change
						newPos = [oldPos(1), oldPos(2)+obj.distanceMoved];
					elseif obj.currentDirection == 2
						% if we move west, only x change
						newPos = [oldPos(1)-obj.distanceMoved, oldPos(2)];
					elseif obj.currentDirection == 3
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

