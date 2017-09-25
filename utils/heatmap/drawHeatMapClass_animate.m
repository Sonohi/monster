


heatmaps_t = 20;

for pp = 1:heatmaps_t
  Heatmaps_structs(pp,:) = load(sprintf('HeatmapClass_%i',pp));
end


Heatmaps = {Heatmaps_structs.HeatMap};


sz = sqrt(length(Heatmaps{1,1}));
x = 1:290/sz:290;
y = 1:290/sz:290;

v = -120:25:10;

hhfig = figure
hold on
HeatMap = Heatmaps{1,:};
StationSNR = reshape([HeatMap.snrVals],2,length(HeatMap));
StationRxPw = reshape([HeatMap.rxPw],2,length(HeatMap));
StationSINR = reshape([HeatMap.SINR],2,length(HeatMap));
StationintSigLoss = reshape([HeatMap.intSigLoss],2,length(HeatMap));
hh = contourf(x,y,reshape(StationRxPw(2,:),sz,sz),v);
heatmap_plot = gca;
xlabel('Metres (x)');
ylabel('Metres (y)');
%c = colorbar;
saveas(hhfig,'Heatmap1.png','png')

pause(0.3)
for plots = 2:length(Heatmaps)
delete(heatmap_plot)
HeatMap = Heatmaps{:,plots};
StationSNR = reshape([HeatMap.snrVals],2,length(HeatMap));
StationRxPw = reshape([HeatMap.rxPw],2,length(HeatMap));
StationSINR = reshape([HeatMap.SINR],2,length(HeatMap));
StationintSigLoss = reshape([HeatMap.intSigLoss],2,length(HeatMap));

hh = contourf(x,y,reshape(StationRxPw(2,:),sz,sz),v);
xlabel('Metres (x)');
ylabel('Metres (y)');
%c = colorbar;
saveas(hhfig,sprintf('Heatmap%i.png',plots),'png')
pause(0.3)
end

