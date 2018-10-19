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
    
    % Results are saved in mat files to speed up the simulation. It can be
    % forced by setting a flag in the config.
    if exist(filename, 'file') && ~param.channel.computeCoverage
        sonohilog('Coverage calculations found, loading from file. Set tag in function call if you require recomputation (e.g. a change in channel)','NFO');
        load(filename)
    else
        sonohilog(sprintf('Calculating coverage for Station %i, EIRP/subcarrier: %s, EIRP(dBm): %s', station.NCellID, num2str(10*log10(station.Tx.getEIRPSubcarrier)+30), num2str(station.Tx.getEIRPdBm)));
        coverage = computeCoverage(station,channel, param);
        save(filename,'coverage')
    end
    sonohilog(sprintf('Coverage of Station: %i, approx. %0.2f (m)/NLOS',station.NCellID,coverage.distance(end)));
    % Plot circles of coverage.
    r = coverage.distance(end);
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
    hCoverage = rectangle(param.LayoutAxes,'Position', [px py d d], 'Curvature', [1,1],'FaceColor',color,'EdgeColor','none','Tag',strcat('coverage',num2str(stationIdx)));
    uistack(hCoverage,'bottom')
end
drawnow
end 