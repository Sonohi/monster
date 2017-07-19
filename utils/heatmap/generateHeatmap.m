function Clusters = generateHeatMap(Stations, Channel, Param)

%   GENERATE HEATMAP is used to gnerate a pathloss map in the scenario
%
%   Generates a heatmap per station.
%
%   Function fingerprint
%   Stations		->  array of eNodeBs
%
%   heatMap 		->  2D matrix with combined pathloss levels

    % Reset channel function
    Channel = Channel.resetWinner;

	% create a dummy UE that we move around in the grid for the heatMap
	%ue = UserEquipment(Param, 99);





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

  ueM = cell(numClusters,1);

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
																'snrVals', zeros(1,length(Stations)), ...
																'evmVals', zeros(1,length(Stations)),...
                                'rxPw',zeros(1,length(Stations)));

		% move along the row for next round
		xa = xc;
      ueM{iCluster} = UserEquipment(Param, 99);
    end





	% now for each station, place the UE at the centre of each cluster and calculate
	for iStation = 1:length(Stations)
        % Associate user with stations
        Stations(iStation).Users = ueM{iCluster}.UeId;

		parfor iCluster = 1:length(Clusters)
            %sonohilog(sprintf('Generating heatmap, cluster %i/%i',iCluster,length(Clusters)),'NFO')
			ueM{iCluster}.Position = [Clusters(iCluster).CC, Param.ueHeight];

            try
                [~, ue_] = Channel.traverse(Stations(iStation),ueM{iCluster});
                Clusters(iCluster).snrVals(iStation) = ue_.RxInfo.SNRdB;
                Clusters(iCluster).rxPw(iStation) = ue_.RxInfo.rxPw;
                sonohilog(sprintf('Saved SNR: %s dB, RxPw: %s dB',num2str(ue_.RxInfo.SNRdB),num2str(ue_.RxInfo.rxPw)),'NFO');
            catch ME
                Clusters(iCluster).snrVals(iStation) = NaN;
               sonohilog(sprintf('Something went wrong... %s',ME.identifier),'NFO')
            end


		end
    end





    save('Heatmap_17_07_MacroMicroBS_Parfor.mat','Clusters')


end
