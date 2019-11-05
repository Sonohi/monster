%
% Utility to process the results of the ueBatchSimulations
%

% create filestrings
%Set your own datestring here to go back, use "yyyy.mm.dd" format
datestring = '';
if strcmp(datestring,'')
  datestring= datestr(datetime, 'yyyy.mm.dd');
end


plotScenarios(datestring);



function plotScenarios(datestring)
  %Create filepaths
  basePath = strcat('examples/ueThroughput/results/', datestring);
  baselinePath = strcat(basePath, '/baseline');
  bandwidthPath = strcat(basePath, '/bandwidth');
  withMicroPath = strcat(basePath, '/withMicro');
  withoutBackhaulPath = strcat(basePath, '/withoutBackhaul');
  withBackhaulPath = strcat(basePath, '/withBackhaul');
  
  %Create figure for baseline, bandwidth and micro scenarios
  ThroughputPlot = figure('Name', 'Throughput');
  xlabel('Time [s]');
  ylabel('Throughput [b]');
  %Plot the throughput
  baselineTotal = plotThroughput(baselinePath, 'Baseline',ThroughputPlot);
  bandwidthTotal = plotThroughput(bandwidthPath, 'Bandwidth',ThroughputPlot);
  withMicroTotal = plotThroughput(withMicroPath, 'With Micro',ThroughputPlot);
  withoutBackhaulTotal = plotThroughput(withoutBackhaulPath, 'Without Backhaul');
  withBackhaulTotal = plotThroughput(withBackhaulPath, 'With Backhaul');
  
  %Plot CDF
  CompareTotalThroughput = figure('Name','Overview: Total throughput CDF');
  plot(baselineTotal(1,:),baselineTotal(2,:),bandwidthTotal(1,:),bandwidthTotal(2,:),...
      withMicroTotal(1,:),withMicroTotal(2,:),...
      withoutBackhaulTotal(1,:),withoutBackhaulTotal(2,:),withBackhaulTotal(1,:),withBackhaulTotal(2,:));
  legend({'Baseline','Bandwidth','With Micro','Without Backhaul','With Backhaul'},'Location','southeast')
  xlabel('avg. throughput per user [Mbps]');
  ylabel('CDF');

end


function totalThroughputPerUe = plotThroughput(filepath, name, varargin)

  % Find file
  folderInfo = dir(strcat(filepath, '/*.mat'));
  fileNames = cellfun(@(x) fullfile(strcat(filepath, '/'), x), {folderInfo.name}, 'UniformOutput', false);
  if ~isempty(fileNames)
    % Always plot latest file
    file = load(fileNames{end});
    Results = file.storedResults.results;

    %Get throughput
    throughput = getThroughput(Results);
    totalThroughput = sum(throughput,2);


    %Get total throughput per Ue
    totalThroughputPerUe = getTotalThroughputPerUe(throughput);   

    %Find number of rounds
    nRounds =length(throughput(:,1));
    rounds = linspace(0,0.001*nRounds,nRounds);
    
    %Load traffic data
    backhaulTraffic = loadBackhaulTraffic(file,nRounds);

    %Plot 
    if isempty(varargin) 
      %Create new figure to plot on
      figure('Name', strcat(name,': Throughput'));
      plot(backhaulTraffic(:,1),backhaulTraffic(:,2),rounds,totalThroughput);
      xlabel('Time [s]');
      ylabel('Throughput [b]');
      legend('Backhaul throughput',strcat(name,' Ue Throughput'));
    else
      figure(varargin{1}); 
      %Plot on top of another figure
      hold on;
      if strcmp(name,'Baseline') 
        %Plot baseline backhaul throughput as well
        plot(backhaulTraffic(:,1),backhaulTraffic(:,2),'DisplayName','Backhaul throughput');
      end
      plot(rounds,totalThroughput,'DisplayName',strcat(name,' Ue Throughput'));
      legend;
    end

  else
    disp('No .mat files found on the specified filepath.');
  end

end


function throughput = getThroughput(Results)
  throughput = Results.throughput;
  throughput(isnan(throughput)) = 0;
end


function totalThroughputPerUe = getTotalThroughputPerUe(throughput)
  %Sum of throughput per user 
  throughput = (sum(throughput,1) * (length(throughput(:,1)))*1e-3)/1e+6; %Convert to Mbps
  throughput = sort(throughput);
  %Make distribution for CDF
  pd = makedist('Normal','mu',mean(throughput)','sigma',std(throughput));
  throughputCDF = cdf(pd,throughput);
  %Save results for comparing
  totalThroughputPerUe = [throughput ; throughputCDF];
end


function backhaulTraffic = loadBackhaulTraffic(file, nRounds)
  Traffic = file.storedTraffic.traffic(:);
  backhaulTraffic = zeros(nRounds,2);
  if Traffic(1).BackhaulOn
    backhaulTraffic(:,1) = Traffic(1).TrafficSourceWithBackhaul(1:nRounds,1);
    for t = 1:length(Traffic)
      backhaulTraffic(:,2) = backhaulTraffic(:,2) + Traffic(t).TrafficSourceWithBackhaul(1:nRounds,2)*length(Traffic(t).AssociatedUeIds);
    end

  else
    backhaulTraffic(:,1) = Traffic(1).TrafficSource(1:nRounds,1);
    for t = 1:length(Traffic)
      backhaulTraffic(:,2) = backhaulTraffic(:,2) + Traffic(t).TrafficSource(1:nRounds,2)*length(Traffic(t).AssociatedUeIds);
    end
  end
    backhaulTraffic=backhaulTraffic(backhaulTraffic(:,1)<nRounds*0.001,:);  
end

