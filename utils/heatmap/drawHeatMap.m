function drawHeatMap(HeatMap, Stations)

%   DRAW HEATMAP is used to plot a pathloss map in the scenario
%
%   Function fingerprint
%   HeatMap		->  struct with heatMap details
%
	% Setup a figure with all the heatmaps singularly

	figure;
	title('SNR heatmaps for single eNodeBs');
	

	sz = sqrt(length(HeatMap));
	x = 1:290/sz:290;
	y = 1:290/sz:290;
	StationSNR = reshape([HeatMap.snrVals],length(Stations),length(HeatMap));

	for iStation = 1:length(Stations)
		subplot(3,2,iStation);
		contourf(x,y,reshape(StationSNR(iStation,:),sz,sz),6);
		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
		xlabel('Metres (x)');
		ylabel('Metres (y)');
		c = colorbar;
		c.Label.String = 'SNR (dB)';
	end
end
