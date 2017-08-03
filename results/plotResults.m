function plotResults(Param, Stations, Users)

	%   PLOT RESULTS is a simple utility to plot some results
	%
	%   Function fingerprint
	%   Param				->  general simulation parameters
	%   Stations		->  eNodebs details for plotting
	%   Users				->  UEs details for plotting

	enbSource = load('results/compiled.mat', 'enbOut');
	ueSource = load('results/compiled.mat', 'ueOut');
	roundx = 1:Param.schRounds;
	power = [enbSource.power];
	util = [enbSource.util];
	bler = [ueSource.bler];
	evm = [ueSource.evm];
	throughput = [ueSource.throughput];
	sinr = [ueSource.sinr];
	snr = [ueSource.snr];

	lineStyle = {'-', '--', ':', '-.'};
	markerStyle = {'o', '+', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};

	% Util plot
	figure('Name', 'eNodeB PRB Utilisation variation (%)');
	title('eNodeB PRB Utilisation variation (%)');
	xlabel('Scheduling round');
	ylabel('eNodeB PRB Utilisation variation (%)');
	utilLegend = '';
	for iStation = 1: Param.numMacro + Param.numMicro
		hold on;
		y(:,1) = util(1,1,iStation, :);
		plot(roundx, y, ...
			'Color', rand(1,3),...
			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
			'Marker', char(markerStyle(randi(length(markerStyle)))),...
			'LineWidth', 2,...
			'DisplayName', strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
	end
	legend('show')

	% SINR plot
	figure('Name', 'UE SINR variation (db)');
	title('UE SINR variation (db)');
	xlabel('Scheduling round');
	ylabel('UE SINR variation (db)');
	for iUser = 1: Param.numUsers
		hold on;
		y(:,1) = sinr(1,1,iUser, :);
		plot(roundx, y, ...
			'Color', rand(1,3),...
			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
			'Marker', char(markerStyle(randi(length(markerStyle)))),...
			'LineWidth', 2,...
			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
	end
	legend('show')

	% CQI plot
	figure('Name', 'UE CQI variation');
	title('UE CQI variation');
	xlabel('Scheduling round');
	ylabel('UE CQI variation');
	for iUser = 1: Param.numUsers
		hold on;
		y(:,1) = cqi(1,1,iUser, :);
		plot(roundx, y, ...
			'Color', rand(1,3),...
			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
			'Marker', char(markerStyle(randi(length(markerStyle)))),...
			'LineWidth', 2,...
			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
	end
	legend('show')

	% SINR/CQI plot
	figure('Name', 'UE SINR/CQI');
	title('UE SINR/CQI');
	xlabel('UE CQI');
	ylabel('UE SINR');
	for iUser = 1: Param.numUsers
		hold on;
		x(:,1) = cqi(1,1,iUser, :);
		y(:,1) = sinr(1,1,iUser, :);
		plot(x, y, ...
			'Color', rand(1,3),...
			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
			'Marker', char(markerStyle(randi(length(markerStyle)))),...
			'LineWidth', 2,...
			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
	end
	legend('show')

	% Power plot
	figure('Name', 'eNodeB Power Used variation (W)');
	title('eNodeB Power Used variation (W)');
	xlabel('Scheduling round');
	ylabel('eNodeB Power Used variation (W)');
	utilLegend = '';
	for iStation = 1: Param.numMacro + Param.numMicro
		hold on;
		y(:,1) = power(1,1,iStation, :);
		plot(roundx, y, ...
			'Color', rand(1,3),...
			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
			'Marker', char(markerStyle(randi(length(markerStyle)))),...
			'LineWidth', 2,...
			'DisplayName', strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
	end
	legend('show')

end
