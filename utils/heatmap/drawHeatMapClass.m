function drawHeatMapClass(HeatMap, Stations)

%   DRAW HEATMAP is used to plot a pathloss map in the scenario
%
%   Function fingerprint
%   HeatMap		->  struct with heatMap details
%
% Setup a figure with all the heatmaps singularly


sz = sqrt(length(HeatMap));
x = 1:290/sz:290;
y = 1:290/sz:290;

classes = unique({Stations.BsClass})


StationSNR = reshape([HeatMap.snrVals],length(classes),length(HeatMap));
StationRxPw = reshape([HeatMap.rxPw],length(classes),length(HeatMap));
StationSINR = reshape([HeatMap.SINR],length(classes),length(HeatMap));
StationintSigLoss = reshape([HeatMap.intSigLoss],length(classes),length(HeatMap));

drawSubplot(x,y,StationSINR,sz,classes,'SINR','SINR')

	function drawSubplot(x,y,z,sz,classes,label,title_s)
		
		figure
		for class = 1:length(classes)
			subplot(3,2,class);
			contourf(x,y,reshape(z(class,:),sz,sz),10);
			title(strcat(title_s,' for class: '));
			xlabel('Metres (x)');
			ylabel('Metres (y)');
			c = colorbar;
			c.Label.String = label;
		end
		
	end


end
