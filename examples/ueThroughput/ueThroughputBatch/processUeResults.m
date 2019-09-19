%
% Utility to process the results of the ueBatchSimulations
%
clear all;

% create filestrings
basePath = strcat('examples/results/ueThroughput/', datestr(datetime, 'yyyy.mm.dd'));
baselinePath = strcat(basePath, '/baseline');
bandwidthPath = strcat(basePath, '/bandwidth');
fewUsersPath = strcat(basePath, '/fewUsers');
withMicroPath = strcat(basePath, '/withMicro');


baselineTotal = plotThroughput(baselinePath, 'Baseline');
bandwidthTotal = plotThroughput(bandwidthPath, 'Bandwidth');
fewUsersTotal = plotThroughput(fewUsersPath, 'Few Users');
withMicroTotal = plotThroughput(withMicroPath, 'With Micro');


%Compare results
CompareTotalThroughput = figure('Name','Overview: Total throughput');
plot(baselineTotal(1,:),baselineTotal(2,:),bandwidthTotal(1,:),bandwidthTotal(2,:),...
      fewUsersTotal(1,:),fewUsersTotal(2,:),withMicroTotal(1,:),withMicroTotal(2,:));
legend({'Baseline','Bandwidth','Few Users','With Micro'},'Location','southeast')
xlabel('avg throughput [Mbps]');
ylabel('CDF');


function totalThroughput = plotThroughput(filepath, name)
  % Find files and start plotting for baseline Case
  folderInfo = dir(strcat(filepath, '/*.mat'));
  fileNames = cellfun(@(x) fullfile(strcat(filepath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
  if ~isempty(fileNames)
    % Always plot latest file

    Results = load(fileNames{end});
    Results = Results.storedResults.results;

    %Plot total throughput
    s = Results.throughput;
    s(isnan(s)) = 0;
    s2 = (sum(s,1) * (length(s(:,1)))*1e-3)/1e+6; %Convert to Mbps
    s2=sort(s2);
    pd = makedist('Normal','mu',mean(s2)','sigma',std(s2));
    s2cdf = cdf(pd,s2);
    %Save results for comparing
    totalThroughput = [s2 ; s2cdf];
    figure('Name', strcat(name,': Total throughput'));
    plot(totalThroughput(1,:),totalThroughput(2,:));
    xlabel('avg throughput [Mbps]');
    ylabel('CDF');
    %Plot backhaul
    % TODO: plot backhaul
    %figure('Name', strcat(name,': Backhaul effect'));

  end

end




