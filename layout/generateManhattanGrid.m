function buildings = generateManhattanGrid(areaSize, heightRange, buildingWidth, roadWidth)
	% Utility to generate a Manhattan grid of buildings
	%
	% :param areaSize: Double the length of a side of the grid
	% :param heightRange: Array<Double> 2x1 array for height range
	% :param buildingWidth: Double building width
	% :param roadWidth: Double road width
	% 
	% :returns buildings: Array<Integer> buildings coordinates
	%

	% Calculate the number of buildings and roads that can fit in the area
	numBuildings = round((areaSize + roadWidth)/(buildingWidth + roadWidth));
	buildings = zeros(numBuildings^2, 5);
	iBuilding = 0;
	for ix = 1:numBuildings
		for iy = 1:numBuildings
			% For each building we calculate the coordinates of the 
			% bottom-left corner A and of the top-right corner B
			xa = (buildingWidth+roadWidth) * (ix - 1);
			ya = (buildingWidth+roadWidth) * (iy - 1);
			xb = xa + buildingWidth;
			yb = ya + buildingWidth;
			iBuilding = iBuilding + 1;
			buildings(iBuilding, :) = [xa, ya, xb, yb, 0]; 
		end
	end
	% Finally, assign random heights to the buildings in the range
	buildings(:,5) = randi([heightRange],[1 length(buildings(:,1))]);
end