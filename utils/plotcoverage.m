function plotcoverage(stations,channel, param)
% For each station calculate the coverage based on the OFDM demodulation
for stationIdx = 1:length(stations)
    station = stations(stationIdx);
    if isstruct(channel.Region)
        region = getfield(channel.Region,strcat(station.BsClass,'Scenario'));
    else
        region = channel.Region;
    end
    filename = sprintf('utils/coverage/coverage_%s_%s_%s.mat',channel.DLMode, region, num2str(station.Pmax));

    if exist(filename, 'file') && ~param.channel.computeCoverage
        sonohilog('Coverage calculations found, loading from file. Set tag in function call if you require recomputation (e.g. a change in channel)','NFO');
        load(filename)
    else
        sonohilog(sprintf('Calculating coverage for Station %i, EIRP/symbol: %s, EIRP(dBm): %s', station.NCellID, num2str(10*log10(station.Tx.getEIRPSymbol)+30), num2str(station.Tx.getEIRPdBm)));
        coverage = computeCoverage(station,channel, param);
        save(filename,'coverage')
    end
    sonohilog(sprintf('Coverage of Station: %i, approx. %i (m)/NLOS',station.NCellID,coverage.distance(end)));
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
    h_coverage = rectangle(param.LayoutAxes,'Position', [px py d d], 'Curvature', [1,1],'FaceColor',color,'EdgeColor','none','Tag',strcat('coverage',num2str(stationIdx)));
    uistack(h_coverage,'bottom')
end
drawnow
end 