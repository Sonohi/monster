util_low = 1:1;
util_high = 90:90;

metrics_arr = cell([length(util_low),length(util_high)]);
powerConsumed = cell([length(util_low),length(util_high)]);
util = cell([length(util_low),length(util_high)]);
util = cell([length(util_low),length(util_high)]);

for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    filename = sprintf('utilLo_%s-utilHi_%s.mat',int2str(util_low(j)),int2str(util_high(k)));
    metrics  = load(strcat('results\',filename));
    
    powerConsumed{j,k} = metrics(1).SimulationMetrics.powerConsumed;
    util{j,k} = metrics(1).SimulationMetrics.util;
  
  end
  
end

%%
% Plot raw power consumption for all stations
num_rounds = length(cell2mat(powerConsumed(1,1)))
figure
hold on
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    power_all_stations = cell2mat(powerConsumed(j,k));
    plot(1:num_rounds, power_all_stations(:,1))
    plot(1:num_rounds, power_all_stations(:,2))
    plot(1:num_rounds, power_all_stations(:,3))
    plot(1:num_rounds, power_all_stations(:,4))
    plot(1:num_rounds, power_all_stations(:,5))
  end
  
end

%%
% Plot raw util for all stations
num_rounds = length(cell2mat(util(1,1)))
figure
hold on
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    util_all_stations = cell2mat(util(j,k));
    plot(1:num_rounds, util_all_stations(:,1))
    plot(1:num_rounds, util_all_stations(:,2))
    plot(1:num_rounds, util_all_stations(:,3))
    plot(1:num_rounds, util_all_stations(:,4))
    plot(1:num_rounds, util_all_stations(:,5))
  end
  
end

%%
% Plot raw throughput for all users
num_rounds = length(cell2mat(util(1,1)))
figure
hold on
for j = 1:numel(util_low)
  for k = 1:numel(util_high)
    util_all_stations = cell2mat(util(j,k));
    plot(1:num_rounds, util_all_stations(:,1))
    plot(1:num_rounds, util_all_stations(:,2))
    plot(1:num_rounds, util_all_stations(:,3))
    plot(1:num_rounds, util_all_stations(:,4))
    plot(1:num_rounds, util_all_stations(:,5))
  end
  
end