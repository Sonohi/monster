function [terrain, trajectories] = loadGeoTerrain(Monster, numUsers)
	%% About
	% Utility to load terrain information from shapefile files
	% 
	% The function loads a shapefile with roads, then drops a user in a random
	% road. A walk is simulated along the road where the user has
	% been dropped for up to the simulation time

%% Load geo data

seed = Monster.Runtime.seed;
velocity = 1.5; % m/s
time = Monster.Runtime.totalRounds*10e-4; % s
roadsFileName = Monster.Config.Terrain.roadsFile;
buildingsFileName = Monster.Config.Terrain.buildingsFile;
roadsShapeFile = shaperead(roadsFileName);
buildingsShapeFile = shaperead(buildingsFileName);
% Extract road coordinates from the shape file
% convert from geodesic WGS84 to ECEF
% elevation is given as an average elevation of the area
averageElevation = 33; % in m

% Create geodesic ellipsoid
wgs84 = wgs84Ellipsoid();

for iRoad = 1: length(roadsShapeFile)
	geoLat = roadsShapeFile(iRoad).Y;
	geoLon = roadsShapeFile(iRoad).X;
	geoH = averageElevation * ones(1, length(geoLat));
	[x, y, ~] = geodetic2ecef(wgs84, geoLat, geoLon, geoH);
	roads(iRoad) = struct(...,
		'x',x,...
		'y', y);
end

for iBuilding = 1: length(buildingsShapeFile)
	geoLat = buildingsShapeFile(iBuilding).Y;
	geoLon = buildingsShapeFile(iBuilding).X;
	geoH = (averageElevation + buildingsShapeFile(iBuilding).h_mean) * ones(1, length(geoLat));
	[x, y, z] = geodetic2ecef(wgs84, geoLat, geoLon, geoH);
	buildings(iBuilding) = struct(...,
		'x',x,...
		'y', y, ...
		'z', z);
end

% Get boundaries to normalise the coordinates
maxX = max(max([roads.x]), max([buildings.x]));
minX = min(min([roads.x]), min([buildings.x]));
maxY = max(max([roads.y]), max([buildings.y]));
minY = min(min([roads.y]), min([buildings.y]));
maxZ = max([buildings.z]);
minZ = min([buildings.z]);
for iRoad = 1 : length(roads)
	normRoads(iRoad) = struct(...
		'x', -(roads(iRoad).x - minX) ./(maxX-minX), ...
		'y', (roads(iRoad).y -minY) ./(maxY-minY));
end
for iBuilding = 1:length(buildings)
	normBuildings(iBuilding) = struct( ...
		'x', (buildings(iBuilding).x - minX) ./(maxX-minX), ...
		'y', (buildings(iBuilding).y - minY) ./(maxY-minY), ...
		'z', (buildings(iBuilding).z - minZ) ./(maxZ-minZ));
end

%% Draw the roads and the buildings on a figure 
figure;
for iRoad = 1:length(normRoads)
	hold on;
	plot(normRoads(iRoad).y, normRoads(iRoad).x, 'k');
end

%% Position user in the normalised road layout
rng(seed);
% Get a random street index from the list of roads
iStartRoad = randi(length(normRoads));
startRoad(1, :) = normRoads(iStartRoad).x;
startRoad(2, :) = normRoads(iStartRoad).y;
startPos = [startRoad(1), startRoad(2)];
plot(startPos(2), startPos(1), 'r^', 'MarkerSize', 8);

%% Construct user trajectory given a total time and average velocity
trajectoryLength = velocity*time; % in m
lengthCovered = 0;
iTrajectory = 1;
iCurrentRoad = iStartRoad;
iCurrentPointRoad = 0;
trajectory = [];
trajectory(1, iTrajectory) = startPos(1);
trajectory(2, iTrajectory) = startPos(2);
usedRoads = [];
usedRoads(end + 1) = iCurrentRoad;
endPos = [];

while lengthCovered < trajectoryLength
	% calculate a possible segment for the next piece of the trajectory
	% As first point, take the latest point inserted in the current trajectory 
	% As second point, take the next one on the current road and evaluate
	% crossroads
	currentRoad = normRoads(iCurrentRoad);
	pointA = [trajectory(1, iTrajectory), trajectory(2, iTrajectory)];
	% Check whether the current road has a next point 
	iCurrentPointRoad = iCurrentPointRoad + 1;
	iNextPointRoad = iCurrentPointRoad + 1;
	roadEnded = false;
	if iNextPointRoad > length(currentRoad.x) || isnan(currentRoad.x(iNextPointRoad))
		% We have reached the end of the current road
		roadEnded = true;
		% In this case we do not update the length traversed, but only look for
		% crossings
		pointB = pointA;
	else
		pointB = [currentRoad.x(iNextPointRoad), currentRoad.y(iNextPointRoad)];
		% calculate the length of this segment
		% revert min-max normalisation of road points to get actual length in
		% metres
		actualA = [...
			pointA(1)*(maxX-minX) + minX,...
			pointA(2)*(maxY-minY) + minY, ...
		];
		actualB = [...
			pointB(1)*(maxX-minX) + minX,...
			pointB(2)*(maxY-minY) + minY, ...
		];
		segmentLength = sqrt((actualB(1) - actualA(1))^2 + (actualB(2) - actualA(2))^2);
		iTrajectory = iTrajectory + 1;
		trajectory(1, iTrajectory) = pointB(1);
		trajectory(2, iTrajectory) = pointB(2);
		lengthCovered = lengthCovered + segmentLength;
		% Check whether this is the last segment and save the terminus in
		% endPos
		if lengthCovered >= trajectoryLength
			endPos = pointB;
		end
		% Plot the segment traversed
		plot([pointA(2), pointB(2)], [pointA(1), pointB(1)], 'r.:', 'MarkerSize', 4, 'LineWidth', 3);
	end
	% Check whether this point is at a crossroad
	% add a tolerance to find a matching point at a crossroad
	delta = 10e-5;
	crossingRoads = struct('iRoad', {}, 'iPoint', {});
	iCrossingRoad = [];
	iCrossingRoadPoint = [];
	for iRoad = 1: length(normRoads) 
		road = normRoads(iRoad);
		foundX = find([road.x] >= (pointB(1) - delta) & [road.x] <= (pointB(1) + delta));
		foundY = find([road.y] >= (pointB(2) - delta) & [road.y] <= (pointB(2) + delta));
		if ~isempty(foundX) && ~isempty(foundY)
			% Add the crossing road to the list
			crossingRoads(end + 1) = struct('iRoad', iRoad, 'iPoint', foundX(1));
		end
	end
	% In case we have crossing roads, randomly choose to turn or remain on
	% the current road
	shouldTurn = rand > 0.5;
	if ~isempty(crossingRoads) && (shouldTurn || roadEnded)
		% Select the new road to use and prefer new unused roads
		iNewRoads = setdiff([crossingRoads.iRoad], usedRoads);
		if ~isempty(iNewRoads)
			% Pick a random road from the new ones and save the index of the
			% crossroad point
			iCurrentRoad = iNewRoads(randi(length(iNewRoads)));
			iCurrentPointRoad = crossingRoads(find([crossingRoads.iRoad] == iCurrentRoad)).iPoint - 1;
			usedRoads(end + 1) = iCurrentRoad;
		else
			% No new roads, walk back a random old one
			iRandomCrossingRoad = randi(length(crossingRoads));
			iCurrentRoad = crossingRoads(iRandomCrossingRoad).iRoad;
			newRoad = normRoads(iCurrentRoad);
			% Get the point at the crossing to find it after flipping the road
			crossingXBeforeFlip = newRoad.x(crossingRoads(iRandomCrossingRoad).iPoint);
			iNotNaN = find(~isnan([newRoad.x]));
			flipX = flip(newRoad.x(iNotNaN));
			flipY = flip(newRoad.y(iNotNaN));
			normRoads(iCurrentRoad) = struct('x', flipX, 'y', flipY);
			iAfterFlip = find(flipX == crossingXBeforeFlip);
			% In case we have a loop road and there is more than 1 match, pick a
			% random point
			iCurrentPointRoad = iAfterFlip(randi(length(iAfterFlip))) - 1;
		end
	elseif roadEnded && isempty(iCrossingRoad)
		% In this case we reached a dead end
		% Create a cleaned reverted road from the current one and traverse it 
		% backwards
		iNotNaN = find(~isnan([currentRoad.x]));
		flipX = flip(currentRoad.x(iNotNaN));
		flipY = flip(currentRoad.y(iNotNaN));
		normRoads(iCurrentRoad) = struct('x', flipX, 'y', flipY);
		iCurrentPointRoad = 0;
	end
		
end
	
% Finally, mark the end of the trajectory
plot(endPos(2), endPos(1), 'rv', 'MarkerSize', 8);

end