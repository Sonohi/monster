function plotcoverage(stations,channel, param)

% For each station calculate the coverage based on the OFDM demodulation
% and no block errors
for stationIdx = 1:length(stations)
    station = stations(stationIdx);
    coverage = computeCoverage(station,channel, param);
    r = coverage.distance(end);
    %th = 0:pi/50:2*pi;
    %x = coverage.distance(end)*cos(th) + station.Position(1);
    %y = coverage.distance(end)*sin(th) + station.Position(2);
    %plot(x,y)
    d = r*2;
    px = station.Position(1) - r;
    py = station.Position(2) - r;
    rectangle('Position', [px py d d], 'Curvature', [1,1]);
end
% For each station plot the range



end 