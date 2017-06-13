function plotResults(Param, utilLoList, utilHiList)

	%   PLOT RESULTS is a simple utility to plot some results
	%
	%   Function fingerprint
	%   Param						->  general simulation parameters
	%   utilLoList			->  list of low utility values used
	%   utilHiList			->  list of high utility values used

	source = load('results/compiled.mat', 'out');
	roundx = 1:Param.schRounds;
	sinr = source.out.sinr;
	cqi = source.out.cqi;
	util = source.out.util;

	% Util plot
	figure('Name', 'eNodeB PRB Utilisation variation (%)');
	for iStation = 1: Param.numMacro + Param.numMicro
		hold on;
		y(:,1) = util(1,1,iStation, :);
		plot(roundx, y, 'Color', rand(1,3))
	end

	% SINR plot
	figure('Name', 'UE SINR variation (db)');
	for iUser = 1: Param.numUsers
		hold on;
		y(:,1) = sinr(1,1,iUser, :);
		plot(roundx, y, 'Color', rand(1,3))
	end

	% CQI plot
	figure('Name', 'UE CQI variation');
	for iUser = 1: Param.numUsers
		hold on;
		y(:,1) = cqi(1,1,iUser, :);
		plot(roundx, y, 'Color', rand(1,3))
	end


end
