function draweHeatMap(HeatMap, Stations)

%   DRAW HEATMAP is used to plot a pathloss map in the scenario
%
%   Function fingerprint
%   HeatMap		->  struct with heatMap details
%
	sz = power(length(HeatMap), 0.5);
	outMap = zeros(sz, sz);
	for iStation = 1:length(Stations)
		for iMap = 1:length(HeatMap)
			outMap(iMap) = HeatMap(iMap).snrVals(iStation);
		end
		figure;
		surf(10*log10(outMap));

	end
end
