function Clusters = generateHeatMapClass(Stations, Channel, Param)

%   GENERATE HEATMAP is used to gnerate a pathloss map in the scenario
%
%   Function fingerprint
%   Stations		->  array of eNodeBs
%
%   heatMap 		->  2D matrix with combined pathloss levels
for iter = 1:20
% Reset channel function
Channel = Channel.resetChannel;

% create a dummy UE that we move around in the grid for the heatMap
ue = UserEquipment(Param, 99);
ue.Scheduled = 1;

% cluster the grid based on the chosen resoultion
% get grid dimensions
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
			monsterLog('You should have stopped clustering!!!!', 'WRN');
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
		'snrVals', zeros(2,1), ...
		'evmVals', zeros(2,1),...
		'rxPw',zeros(2,1),...
		'intSigLoss',zeros(2,1),...
		'SINR',zeros(2,1));

	% move along the row for next round
	xa = xc;
end


% Find number of base station types
% A model is created for each type
classes = unique({Stations.BsClass});
for class = 1:length(classes)
	varname = classes{class};
	types.(varname) = find(strcmp({Stations.BsClass},varname));
end

Snames = fieldnames(types);

% local copy
StationsCopy = Stations;
% Reset user association
for iStation = 1:length(Stations)
	StationsCopy(iStation).Users = zeros(15,1);
	% In the stations copy, set the txWaveform etc from the dummy frames info
	StationsCopy(iStation).Tx.Waveform = StationsCopy(iStation).Tx.Frame;
	StationsCopy(iStation).Tx.WaveformInfo = StationsCopy(iStation).Tx.FrameInfo;
	StationsCopy(iStation).Tx.ReGrid = StationsCopy(iStation).Tx.FrameGrid;
end

for model = 2:numel(Snames)
	stations = types.(Snames{model});
  for iCluster = 1:length(Clusters)
    warning('off','all')
		% local copy
		ueCopy = ue;
    StationsCopy_ = StationsCopy(stations);
		ueCopy.Position = [Clusters(iCluster).CC, Param.ueHeight];
		StationID = Channel.getAssociation(StationsCopy_,ueCopy);
    StationsCopy_([StationsCopy_.NCellID] == StationID).resetSchedule();
		StationsCopy_([StationsCopy_.NCellID] == StationID).Users(1) = ueCopy.NCellID;
    StationsCopy_([StationsCopy_.NCellID] == StationID).Schedule(1).UeId = ueCopy.NCellID;
		ueCopy.NCellID = StationID;
    
    Channel_ = Channel.setupChannel(StationsCopy_,ueCopy);
    [ueCopy, Channel_] = syncRoutine(StationsCopy_, ueCopy, Channel_, Param);

	
			[~, ueCopy] = Channel_.traverse(StationsCopy_,ueCopy,'downlink');
			Clusters(iCluster).snrVals(model) = ueCopy.Rx.SNRdB;
			Clusters(iCluster).rxPw(model) = ueCopy.Rx.RxPwdBm;
			Clusters(iCluster).SINR(model) = ueCopy.Rx.SINRdB;
			Clusters(iCluster).intSigLoss(model) = ueCopy.Rx.IntSigLoss;
			monsterLog(sprintf('Saved SNR: %s dB, RxPw: %s dB, SINR: %s dB',num2str(ueCopy.Rx.SNRdB),num2str(ueCopy.Rx.RxPwdBm),num2str(ueCopy.Rx.SINRdB)),'NFO');
% 		catch ME
% 			Clusters(iCluster).snrVals(model) = NaN;
% 			Clusters(iCluster).rxPw(model) = NaN;
% 			Clusters(iCluster).SINR(model) = NaN;
% 			Clusters(iCluster).intSigLoss(model) = NaN;
% 			monsterLog(sprintf('Something went wrong... %s',ME.identifier),'WRN')
% 		end

	end

end


% Renaming to avoid fuck-ups
HeatMap = Clusters;
EnodeBs = StationsCopy;
save(sprintf('HeatmapClass_%i.mat',iter),'HeatMap','EnodeBs');

end
end
