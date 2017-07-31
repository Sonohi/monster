function drawHeatMap(HeatMap, Stations)

%   DRAW HEATMAP is used to plot a pathloss map in the scenario
%
%   Function fingerprint
%   HeatMap		->  struct with heatMap details
%
	% Setup a figure with all the heatmaps singularly


	sz = sqrt(length(HeatMap));
	x = 1:290/sz:290;
	y = 1:290/sz:290;
	StationSNR = reshape([HeatMap.snrVals],length(Stations),length(HeatMap));
    StationRxPw = reshape([HeatMap.rxPw],length(Stations),length(HeatMap));
    StationSINR = reshape([HeatMap.SINR],length(Stations),length(HeatMap));
    StationintSigLoss = reshape([HeatMap.intSigLoss],length(Stations),length(HeatMap));
    
    
    
%     figure
% 	for iStation = 1:length(Stations)
% 		subplot(3,2,iStation);
% 		contourf(x,y,reshape(StationSNR(iStation,:),sz,sz),10);
% 		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
% 		xlabel('Metres (x)');
% 		ylabel('Metres (y)');
% 		c = colorbar;
% 		c.Label.String = 'SNR (dB)';
% 	end
% 
% 	figure('Name', 'Mean SNR for complete layout');
% 	AggreagatedSNR = mean(StationSNR);
% 	contourf(x,y,reshape(AggreagatedSNR,sz,sz),10);
% 	xlabel('Metres (x)');
% 	ylabel('Metres (y)');
% 	c = colorbar;
% 	c.Label.String = '\mu SNR (dB)';
% 
% 
%     figure
% 	for iStation = 1:length(Stations)
% 		subplot(3,2,iStation);
% 		contourf(x,y,reshape(StationRxPw(iStation,:),sz,sz),10);
% 		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
% 		xlabel('Metres (x)');
% 		ylabel('Metres (y)');
% 		c = colorbar;
% 		c.Label.String = 'P_{Rx}(dB)';
% 	end
% 
% 	figure('Name', 'Mean Rx power for complete layout');
% 	AggreagatedRxPw = mean(StationRxPw);
% 	contourf(x,y,reshape(AggreagatedRxPw,sz,sz),10);
% 	xlabel('Metres (x)');
% 	ylabel('Metres (y)');
% 	c = colorbar;
% 	c.Label.String = '\mu P_{Rx} (dB)';

    %% 
% 
    figure
	for iStation = 1:length(Stations)
		subplot(3,2,iStation);
		contourf(x,y,reshape(StationSINR(iStation,:),sz,sz),10);
		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
		xlabel('Metres (x)');
		ylabel('Metres (y)');
		c = colorbar;
		c.Label.String = 'SINR(dB)';
	end

	figure('Name', 'Mean SINR for complete layout');
	AggreagatedSINR = mean(StationSINR);
	contourf(x,y,reshape(AggreagatedSINR,sz,sz),10);
	xlabel('Metres (x)');
	ylabel('Metres (y)');
	c = colorbar;
	c.Label.String = '\mu SINR (dB)';
    
    %% 

        figure
	for iStation = 1:length(Stations)
		subplot(3,2,iStation);
		contourf(x,y,reshape(StationintSigLoss (iStation,:),sz,sz),10);
		title(strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
		xlabel('Metres (x)');
		ylabel('Metres (y)');
		c = colorbar;
		c.Label.String = 'Loss(dB)';
	end

	figure('Name', 'Mean loss (interference) for complete layout');
	AggreagatedIntSigLoss = mean(StationintSigLoss );
	contourf(x,y,reshape(AggreagatedIntSigLoss,sz,sz),10);
	xlabel('Metres (x)');
	ylabel('Metres (y)');
	c = colorbar;
	c.Label.String = '\mu Loss (dB)';
    
    
    
end
