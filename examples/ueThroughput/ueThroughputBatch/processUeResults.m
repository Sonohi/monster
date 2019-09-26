%
% Utility to process the results of the ueBatchSimulations
%
clear all;

% create filestrings
%Set your own datestring here to go back, use "yyyy.mm.dd" format
datestring = '';
if strcmp(datestring,'')
  datestring= datestr(datetime, 'yyyy.mm.dd');
end
basePath = strcat('examples/ueThroughput/results/', datestring);
baselinePath = strcat(basePath, '/baseline');
bandwidthPath = strcat(basePath, '/bandwidth');
withMicroPath = strcat(basePath, '/withMicro');
withoutBackhaulPath = strcat(basePath, '/withoutBackhaul');
withBackhaulPath = strcat(basePath, '/withBackhaul');


baselineTotal = plotThroughput(baselinePath, 'Baseline');
bandwidthTotal = plotThroughput(bandwidthPath, 'Bandwidth');
withMicroTotal = plotThroughput(withMicroPath, 'With Micro');
withoutBackhaulTotal = plotThroughput(withoutBackhaulPath, 'Without Backhaul');
withBackhaulTotal = plotThroughput(withBackhaulPath, 'With Backhaul');


%Compare results throughput
CompareTotalThroughput = figure('Name','Overview: Total throughput CDF');
plot(baselineTotal(1,:),baselineTotal(2,:),bandwidthTotal(1,:),bandwidthTotal(2,:),...
	  withMicroTotal(1,:),withMicroTotal(2,:),...
	  withoutBackhaulTotal(1,:),withoutBackhaulTotal(2,:),withBackhaulTotal(1,:),withBackhaulTotal(2,:));
legend({'Baseline','Bandwidth','With Micro','Without Backhaul','With Backhaul'},'Location','southeast')
xlabel('avg throughput [Mbps]');
ylabel('CDF');


function totalThroughput = plotThroughput(filepath, name)
  % Find files and start plotting for baseline Case
  folderInfo = dir(strcat(filepath, '/*.mat'));
  fileNames = cellfun(@(x) fullfile(strcat(filepath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
  if ~isempty(fileNames)
    % Always plot latest file

    results = load(fileNames{end});
    Results = results.storedResults.results;

    %Plot total throughput
    s = Results.throughput;
    s(isnan(s)) = 0;
    s2 = (sum(s,1) * (length(s(:,1)))*1e-3)/1e+6; %Convert to Mbps
    s2=sort(s2);
    pd = makedist('Normal','mu',mean(s2)','sigma',std(s2));
    s2cdf = cdf(pd,s2);
    %Save results for comparing
    totalThroughput = [s2 ; s2cdf];
    %Plot backhaul
    %Load traffic data
    Traffic = results.storedTraffic.traffic(:);
    nRounds =length(s(:,1));
    rounds = linspace(0,0.001*nRounds,nRounds);
    T = zeros(nRounds,2);
    T(:,1) = Traffic(1).TrafficSource(1:nRounds,1);
    for t = 1:length(Traffic)
      T(:,2) = T(:,2) + Traffic(t).TrafficSource(1:nRounds,2)*length(Traffic(t).AssociatedUeIds);
    end
    T=T(T(:,1)<nRounds*0.001,:);
    throughput = sum(s,2);

    figure('Name', strcat(name,': Throughput'));
    plot(T(:,1),T(:,2),rounds,throughput);
    xlabel('Time [s]');
    ylabel('Throughput [b]');
    legend('Source throughput','Ue Throughput');
  end

end




