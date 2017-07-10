function Clusters = generateHeatMap(Stations, Channel, Param)

%   GENERATE HEATMAP is used to gnerate a pathloss map in the scenario
%
%   Function fingerprint
%   Stations		->  array of eNodeBs
%
%   heatMap 		->  2D matrix with combined pathloss levels

	% create a dummy UE that we move around in the grid for the heatMap
	ue = UserEquipment(Param, 99);

	% cluster the grid based on the chosen resoultion
	% get grid dimensions TODO extend to more shapes
	xdim = Param.area(3) - Param.area(1);
	ydim = Param.area(4) - Param.area(2);
	numXClusters = floor(xdim/Param.heatMapRes);
	numYClusters = floor(ydim/Param.heatMapRes);
	numClusters = power(min(numXClusters, numYClusters),2);

	% set initial position to start the clustering
	xa = 0;
	ya = 0;
	for iCluster = 1:numClusters

		% the Clusters are created by row starting from [0,0]
		% if xa is at the edge, we need to reset it and update ya
		if xa >= xdim
			xa = 0;
			ya = ya + Param.heatMapRes;
			% on the other hand, when ya reaches the top we are done and it should
			% coincide with the nuber of Clusters
			if ya >= ydim
				sonohilog('You should have stopped clustering!!!!', 'WRN');
			end
		end
		xc = xa + Param.heatMapRes;
		yc = ya + Param.heatMapRes;
		Clusters(iCluster) = struct(...
																'clusterIndex', iCluster,...
																'A', [xa, ya],...
																'B', [xc, ya],...
																'C', [xc, yc],...
																'D', [xa, yc],...
																'CC', [xa + (xc-xa)/2, ya + (yc-ya)/2],...
																'snrVals', zeros(1, length(Stations)), ...
																'evmVals', zeros(1, length(Stations)));

		% move along the row for next round
		xa = xc;
	end

	% now for each station, place the UE at the centre of each cluster and calculate
	for iStation = 1:length(Stations)
		for iCluster = 1:length(Clusters)
			ue.Position = [Clusters(iCluster).CC, Param.ueHeight];
			[Clusters(iCluster).snrVals(iStation), Clusters(iCluster).evnVals(iStation)] = ...
				calculateSignalDegradation(Channel, ue, Stations(iStation));
		end
	end
end