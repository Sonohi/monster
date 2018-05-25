classdef MMobility < handle
	% Directions defined as:
	% 
	% * 1 = N
	% * 2 = W
	% * 3 = S
	% * 4 = E
	
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
		turningDistance;
		crossingDistance;
		buildingFootprints;
		movementSpeed;
		distanceMoved;
		westEast = [2, 4];
		northSouth = [1, 3];
	end

	methods
		function obj = MMobility(scenario, velocity, seed, Param)
			% Constructor
			if ~strcmp(scenario, 'pedestrian')
				sonohilog(sprintf('Mobility scenario %s not supported',scenario),'ERR')
			end
			
			% Set arguments
			obj.Scenario = scenario;
			obj.Velocity = velocity;
			obj.Seed = seed;
			obj.Rounds = Param.schRounds;
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
			% Computes a trajectory with pedestrian type movement. Uses a state machine approach to randomize the walk. 
			% Turns and crosses are based on turning and crossing times, as well as turn and crossing distances. These are set in :meth:`MMobility.setParameters`
			rng(obj.Seed);
			[start, startSide] = obj.getRandomBuilding();
			startPos = zeros(1,2);
			[startPos(1), startPos(2)] = obj.getExitPoint(start, startSide);

			% Add starting position to trajectory
			obj.Trajectory(1,:) = startPos;

			% Given the starting side, chose a random direction
			% e.g. if starting side of the building is north or south, user can only
			% move west or east.
			nextState = 'moving';
			stateVar = obj.initializeStateVars(start, startSide);
			for round = 2:obj.Rounds
					state = nextState;
					
					switch state
						case 'moving'
							% Reset state variables
							stateVar.turnOrCross = false;
							stateVar.turn = false;
							stateVar.cross = false;
							
							oldPos = obj.Trajectory(round-1,:);
							newPos = obj.movement(stateVar.currentDirection, oldPos);
							if ~stateVar.justTurnedOrCrossed
								stateVar.turnOrCross = obj.checkTurnOrCross(stateVar, newPos);
							end
							
							if stateVar.turnOrCross
								[stateVar.turn, stateVar.cross, stateVar.currentDirection] = obj.decideTurnOrCross(stateVar, newPos);
								if stateVar.turn
									obj.Trajectory(round,:) = oldPos;
									nextState = 'turning';
								elseif stateVar.cross
									obj.Trajectory(round,:) = oldPos;
									nextState = 'crossing';
								end
							else
								obj.Trajectory(round,:) = newPos;
							end
							stateVar.justTurnedOrCrossed = false;
							
						case 'turning'
							if stateVar.timeLeftForTurning > 0
								stateVar.timeLeftForTurning = stateVar.timeLeftForTurning - obj.TimeStep;
								obj.Trajectory(round,:) = obj.Trajectory(round-1,:);
							else
								% Turning corner
								oldPos = obj.Trajectory(round-1,:);
								newPos = obj.movement(stateVar.currentDirection, oldPos);
								obj.Trajectory(round,:) = newPos;
								stateVar.turningDistance = stateVar.turningDistance - obj.distanceMoved;
								if stateVar.turningDistance <= 0
									stateVar = obj.setTurnedStateVars(stateVar, newPos);
									nextState = 'moving';
								end
	
							end
							
						case 'crossing'
							if stateVar.timeLeftForCrossing > 0
							 stateVar.timeLeftForCrossing = stateVar.timeLeftForCrossing - obj.TimeStep;
							 obj.Trajectory(round,:) = obj.Trajectory(round-1,:);
							else
								% Crossing street
								oldPos = obj.Trajectory(round-1,:);
								newPos = obj.movement(stateVar.currentDirection, oldPos);
								stateVar.crossingDistance = stateVar.crossingDistance - obj.distanceMoved;
								streetIsCrossed = obj.checkStreetIsCrossed(stateVar);
								obj.Trajectory(round,:) = newPos;
								if streetIsCrossed
										stateVar = obj.setCrossedStateVars(stateVar, newPos);
										nextState = 'moving';
								end
								
							end

					end
			end
		end

		function stateVar = initializeStateVars(obj, start, startSide)
			stateVar = struct();
			stateVar.timeLeftForCrossing = obj.pedestrianCrossingPause;
			stateVar.timeLeftForTurning = obj.pedestrianTurnPause;
			stateVar.turningDistance = obj.turningDistance;
			stateVar.crossingDistance = obj.crossingDistance; %2 walldistance to move past crossing/turning point
			stateVar.currentSide = startSide;
			stateVar.currentDirection = obj.getMovementDirection(stateVar);
			stateVar.currentBuilding = obj.buildingFootprints(start,:);
			stateVar.turn = false;
			stateVar.cross = false;
			stateVar.turnOrCross = false;
			stateVar.justTurnedOrCrossed = false;
		end
		
		function stateVar = setCrossedStateVars(obj, stateVar, newPos)
			stateVar.currentBuilding = obj.findClosestBuilding(newPos);
			stateVar.currentSide = obj.getBuildingSide(stateVar, newPos);
			stateVar.crossingDistance = obj.crossingDistance;
			stateVar.timeLeftForCrossing = obj.pedestrianCrossingPause;
			stateVar.justTurnedOrCrossed = true;
		end

		function stateVar = setTurnedStateVars(obj, stateVar, newPos)
			stateVar.justTurnedOrCrossed = true;
			stateVar.currentSide = obj.getBuildingSide(stateVar, newPos);
			stateVar.timeLeftForTurning = obj.pedestrianTurnPause;
			stateVar.turningDistance = obj.turningDistance;
		end
		
		function obj = setParameters(obj)
			% Sets parameters for mobility, default values are given as
			%
			% * Road width = 10m
			% * Lane width = Road width / 3
			% * Wall distance = 1m 
			% 
			% For the scenario of **pedestrian** the parameters are given as
			%
			% * pedestrianTurnPause = 0.02 s
			% * pedestrianCrossingPause = 5 s
			% * turningDistance = 2 * wall distance
			% * crossingDistance = road width + 2*wall distance
			obj.roadWidth = 10;
			obj.laneWidth = obj.roadWidth / 3;
			obj.wallDistance = 1;
			obj.movementSpeed = obj.Velocity; % [m/s]
			if strcmp(obj.Scenario, 'pedestrian')
				% TODO: randomize wait times between appropriate numbers.
				obj.pedestrianTurnPause = 0.02; % 20 ms of pause;
				obj.pedestrianCrossingPause = 5; % Roughly 5 seconds for crossing, equal to 5000 rounds
				obj.turningDistance = 2*obj.wallDistance; % When turning we want to move past the corner
				obj.crossingDistance = obj.roadWidth + 2*obj.wallDistance; %When crossing we want to move past the corner
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
			building = obj.buildingFootprints(intersect(cornerXIdx, cornerYIdx),:);
			
			if isempty(building)
				sonohilog('Something went wrong in finding closest building','ERR')
				
			end
			
		end
		
		function [streetCrossed] = checkStreetIsCrossed(obj, stateVar)
			streetCrossed = false;
			if stateVar.crossingDistance <= 0
				streetCrossed = true;
			end
			
		end
		
		function direction = getMovementDirection(obj, stateVar)
			if any(ismember(obj.northSouth, stateVar.currentSide))
				direction = obj.westEast(randi(2));
			else
				direction = obj.northSouth(randi(2));
			end

		end
		
		function side = getBuildingSide(obj, stateVar, newPos)
			if round(newPos(1),5) < round(stateVar.currentBuilding(1),5)
				side = 2;
			elseif round(newPos(1),5) > round(stateVar.currentBuilding(3),5)
				side = 4;
			elseif round(newPos(2),5) < round(stateVar.currentBuilding(2),5)
				side = 3;
			elseif round(newPos(2),5) > round(stateVar.currentBuilding(4),5)
				side = 1;
			end
		end
		
		function [turn, cross, directionNew] = decideTurnOrCross(obj, stateVar, newPos)
				% Pick new direction, not possible to go back.
				possibledirections = [];
				if any(ismember(obj.northSouth, stateVar.currentDirection))
					possibledirections = [possibledirections stateVar.currentDirection];
					possibledirections = [possibledirections obj.westEast];
				else
					possibledirections = [possibledirections stateVar.currentDirection];
					possibledirections = [possibledirections obj.northSouth];
				end

				% Checking the current position against the building grid to ensure we're not moving beyond.
				if round(newPos(2),5) > round(max(obj.buildingFootprints(:,4)),5)
					% Remove 1 from possible directions
					possibledirections = possibledirections(possibledirections ~= 1);
				elseif round(newPos(1),5) < round(min(obj.buildingFootprints(:,1)),5)
					% Remove 2 from possible directions
					possibledirections = possibledirections(possibledirections ~= 2);
				elseif round(newPos(2),5) < round(min(obj.buildingFootprints(:,2)),5)
					% Remove 3 from possible directions
					possibledirections = possibledirections(possibledirections ~= 3);
				elseif round(newPos(1),5) > round(max(obj.buildingFootprints(:,3)),5)
					% Remove 4 from possible directions
					possibledirections = possibledirections(possibledirections ~= 4);
				end

				directionNew = possibledirections(randi(length(possibledirections)));
				turn = false;
				cross = false;
				if (stateVar.currentSide == 1) && (directionNew == 3)
					turn = true;
				elseif (stateVar.currentSide == 3) && (directionNew == 1)
					turn = true;
				elseif (stateVar.currentSide == 2) && (directionNew == 4)
					turn = true;
				elseif (stateVar.currentSide == 4) && (directionNew == 2)
					turn = true;
				else 
					cross = true;
				end
		end
		
		function [turnOrCross] = checkTurnOrCross(obj, stateVar, newPos)
				turnOrCross = false;
				if (stateVar.currentDirection == 1) && (round(newPos(2),5) > round(stateVar.currentBuilding(4),5)+obj.wallDistance)
						turnOrCross = true;
					elseif (stateVar.currentDirection == 2) && (round(newPos(1),5) < round(stateVar.currentBuilding(1),5)-obj.wallDistance)
						turnOrCross = true;
					elseif (stateVar.currentDirection == 3) && (round(newPos(2),5) < round(stateVar.currentBuilding(2),5)-obj.wallDistance)
						turnOrCross = true;
					elseif (stateVar.currentDirection == 4) && (round(newPos(1),5) > round(stateVar.currentBuilding(3),5)+obj.wallDistance)
						turnOrCross = true;
				end
			
		end
		
		function newPos = movement(obj, direction, oldPos)
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

