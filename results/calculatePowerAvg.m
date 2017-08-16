function [avg, sd] = calculatePowerAvg(data)

%   CALCULATE POWER AVERAGE	computes the aggregated results for power
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
			temp(l, h, r) = mean([data(l, h, r, :).power]);
		end
		try
			avg(l, h) = mean(temp(l, h, :));
			sd(l, h) = std(temp(l, h, :));
		catch ME
			disp(ME);
		end
	end
end

end
