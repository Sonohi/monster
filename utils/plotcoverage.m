function plotcoverage(stations,channel, param)
% For each station calculate the coverage based on the OFDM demodulation
% and no block errors
for stationIdx = 1:length(stations)
    station = stations(stationIdx);
    sonohilog(sprintf('Station %i, EIRP/symbol: %s, EIRP(dBm): %s', station.NCellID, num2str(10*log10(station.Tx.getEIRPSymbol)+30), num2str(station.Tx.getEIRPdBm)));
    coverage = computeCoverage(station,channel, param);
    r = coverage.distance(end);
    %th = 0:pi/50:2*pi;
    %x = coverage.distance(end)*cos(th) + station.Position(1);
    %y = coverage.distance(end)*sin(th) + station.Position(2);
    %plot(x,y)
    d = r*2;
    px = station.Position(1) - r;
    py = station.Position(2) - r;
    if strcmp(station.BsClass,'macro')
        color = [0, 0.6, 0.2, 0.05];
    elseif strcmp(station.BsClass,'micro')
        color = [0.6, 0.2, 0, 0.05];
    else 
        color = [0.2, 0.6, 0, 0.05];
    end
    h_coverage = rectangle(Param.LayoutAxes,'Position', [px py d d], 'Curvature', [1,1],'FaceColor',color,'EdgeColor','none','Tag',strcat('coverage',num2str(stationIdx)));
    uistack(h_coverage,'bottom')
end
refresh(Param.LayoutFigure)
end 