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