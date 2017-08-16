function [avg, sd] = calculateBerAvg(data)

%   CALCULATE BER AVERAGE computes the aggregated results for BER
%
%   Function fingerprint
%   data		->  compiled result
%
%   avg			->  average
%   sd			->  standard deviation

%TODO change from the lazy way of a for loop and use matrix operations
for l = 1:size(data,1)
	for h = 1:size(data, 2)
		for r = 1:size(data, 3)
			blk(1:size(data,4)) =  data(l, h, r, :).bits;
			temp(l, h, r) = mean([blk.err])/mean([blk.tot]);
		end
		avg(l, h) = mean(temp(l, h, :));
		sd(l, h) = std(temp(l, h, :));
	end
end

end
