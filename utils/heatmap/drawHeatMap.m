function drawHeatMap(HeatMap, Stations)

%   DRAW HEATMAP is used to plot a pathloss map in the scenario
%
%   Function fingerprint
%   HeatMap		->  struct with heatMap details
%
	% Setup a figure with all the heatmaps singularly

	figure('Name', 'SNR heatmaps for single eNodeBs');

	sz = sqrt(length(HeatMap));
	x = 1:290/sz:290;
	y = 1:290/sz:290;
	StationSNR = reshape([HeatMap.snrVals],length(Stations),length(HeatMap));
  StationRxPw = reshape([HeatMap.rxPw],length(Stations),length(HeatMap));
    figure
	for iStation = 1:length(Stations)
		subplot(3,2,iStation);
		contourf(x,y,reshape(StationSNR(iStation,:),sz,sz),10);
		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
		xlabel('Metres (x)');
		ylabel('Metres (y)');
		c = colorbar;
		c.Label.String = 'SNR (dB)';
	end

	figure('Name', 'Mean SNR for complete layout');
	AggreagatedSNR = mean(StationSNR);
	contourf(x,y,reshape(AggreagatedSNR,sz,sz),10);
	xlabel('Metres (x)');
	ylabel('Metres (y)');
	c = colorbar;
	c.Label.String = '\mu SNR (dB)';


    figure
	for iStation = 1:length(Stations)
		subplot(3,2,iStation);
		contourf(x,y,reshape(StationRxPw(iStation,:),sz,sz),10);
		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
		xlabel('Metres (x)');
		ylabel('Metres (y)');
		c = colorbar;
		c.Label.String = 'P_{Rx}(dB)';
	end

	figure('Name', 'Mean Rx power for complete layout');
	AggreagatedRxPw = mean(StationRxPw);
	contourf(x,y,reshape(AggreagatedRxPw,sz,sz),10);
	xlabel('Metres (x)');
	ylabel('Metres (y)');
	c = colorbar;
	c.Label.String = '\mu P_{Rx} (dB)';

end
