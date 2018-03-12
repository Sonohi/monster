%% DATA PARSER is use to generate charts of the results
% feel free to comment out the blocks not needed and modify this script in whichever way suits your needs

util_low = [20 40 60];
util_high = 100 ;
seeds = [5 8 42 79 153];

metrics_arr = cell([length(seeds), length(util_low), length(util_high)]);
powerConsumed = cell([length(seeds), length(util_low),length(util_high)]);
util = cell([length(seeds), length(util_low),length(util_high)]);
thr = cell([length(seeds), length(util_low),length(util_high)]);
ber = cell([length(seeds), length(util_low),length(util_high)]);
rsrq = cell([length(seeds), length(util_low),length(util_high)]);
bler = cell([length(seeds), length(util_low),length(util_high)]);
sinr = cell([length(seeds), length(util_low),length(util_high)]);
harq = cell([length(seeds), length(util_low),length(util_high)]);
powerState = cell([length(seeds), length(util_low),length(util_high)]);

for z = 1:numel(seeds)
	for j = 1:numel(util_low)
		for k = 1:numel(util_high)
			filename = sprintf('seed_%s-utilLo_%s-utilHi_%s.mat',int2str(seeds(z)), int2str(util_low(j)),int2str(util_high(k)));
			metrics  = load(strcat('results/',filename));
			powerConsumed{z, j, k} = metrics(1).SimulationMetrics.powerConsumed;
			util{z, j, k} = metrics(1).SimulationMetrics.util;
			thr{z, j, k} = metrics(1).SimulationMetrics.throughput;
			ber{z, j, k} = metrics(1).SimulationMetrics.ber;
			bler{z, j, k} = metrics(1).SimulationMetrics.bler;
			rsrq{z, j, k} = metrics(1).SimulationMetrics.rsrqdB;
			sinr{z, j, k} = metrics(1).SimulationMetrics.sinrdB;
			harq{z, j, k} = metrics(1).SimulationMetrics.harqRtx;
			powerState{z, j, k} = metrics(1).SimulationMetrics.powerState;
		end
	end
end

%% Prepare the baseline (basically when we have no energy saving)
powerConsumedBaseAvg = zeros(length(seeds), 1);
utilBaseAvg = zeros(length(seeds), 1);
harqBaseAvg = zeros(length(seeds), 1);
thrBaseAvg = zeros(length(seeds), 1);

for z = 1:numel(seeds)
	filename = sprintf('seed_%s-utilLo_1-utilHi_100.mat',int2str(seeds(z)));
	metricsBase  = load(strcat('results/',filename));
	powerConsumedBaseAvg(z) = sum(mean(metricsBase(1).SimulationMetrics.powerConsumed));
	utilBaseAvg(z) = sum(mean(metricsBase(1).SimulationMetrics.util));
	thrBaseAvg(z) = sum(mean(metricsBase(1).SimulationMetrics.throughput));
 	harqBase = metricsBase(1).SimulationMetrics.harqRtx;
	harqBaseAvg(z) = sum(harqBase(length(harqBase), :));
end

% calculate mean and variance
powerConsumedBaseMean = mean(powerConsumedBaseAvg);
powerConsumedBaseDelta = std(powerConsumedBaseAvg);
utilBaseMean = mean(utilBaseAvg);
utilBaseDelta = std(utilBaseAvg);
thrBaseMean = mean(thrBaseAvg);
thrbaseDelta = std(thrBaseAvg);
harqBaseMean = mean(harqBaseAvg);
harqBaseDelta = std(harqBaseAvg);

% Power saved 
figure;
title('Power saved (%)');
hold on;
powerPercent = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		powerConsumedAvg = zeros(length(seeds), 1);
		for z = 1:numel(seeds)
			powerConsumedAvg(z) = sum(mean(powerConsumed{z,j,k}));
		end
		powerConsumedMean = mean(powerConsumedAvg);
		powerPercent(numel(util_high)*(j-1) + k) = 100*(1 - powerConsumedMean/powerConsumedBaseMean);
	end
end
bar(powerPercent);

% HARQ 
figure;
title('Reduction of HARQ retransmissions (%)');
hold on;
harqPercent = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		harqAvg = zeros(length(seeds), 1);
		for z = 1:numel(seeds)
			harqTot = harq{z,j,k};
			harqAvg(z) = sum(harqTot(length(harqTot), :));
		end
		harqMean = mean(harqAvg);
		harqPercent(numel(util_high)*(j-1) + k) = 100*(1 - harqMean/harqBaseMean);
	end
end
bar(harqPercent);

% Throughput 
figure;
title('Throughput');
hold on;
thrPercent = zeros(numel(util_low) + numel(util_high), 1);
for j = 1:numel(util_low)
	for k = 1:numel(util_high)
		thrAvg = zeros(length(seeds), 1);
		for z = 1:numel(seeds)
			thrAvg(z) = sum(mean(thr{z,j,k}));
		end
		thrMean = mean(thrAvg);
		thrPercent(numel(util_high)*(j-1) + k) = 100*(1 - thrMean/thrBaseMean);
	end
end
bar(thrPercent);

