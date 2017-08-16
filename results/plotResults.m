function plotResults(Param, Stations, Users)

	%   PLOT RESULTS is a simple utility to plot some results
	%
	%   Function fingerprint
	%   Param				->  general simulation parameters
	%   Stations		->  eNodebs details for plotting
	%   Users				->  UEs details for plotting

	load('results/compiled.mat', 'enbOut');
	load('results/compiled.mat', 'ueOut');
	utilLo = 1:Param.utilLoThr;
	utilHi = Param.utilHiThr:100;

	[powerAvg, powerSd] = calculatePowerAvg(enbOut);
	[utilAvg, utilSd] = calculateUtilAvg(enbOut);
	[blerAvg, blerSd] = calculateBlerAvg(ueOut);
	[berAvg, berSd] = calculateBerAvg(ueOut);
	[sinrAvg, sinrSd] = calculateSinrAvg(ueOut);
	[evmAvg, evmSd] = calculateEvmAvg(ueOut);
	[cqiAvg, cqiSd] = calculateCqiAvg(ueOut);
	%[thrAvg, thrSd] = calculateThrAvg(ueOut);

% 	lineStyle = {'-', '--', ':', '-.'};
% 	markerStyle = {'o', '+', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};

	% Power plot
	figure('Name', 'eNodeBs Power Used average(W)');
	title('eNodeBs Power Used (W)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, powerAvg);
	c = colorbar;
	c.Label.String = 'Average Power Used (W)';

	% Util plot
	figure('Name', 'eNodeBs PRB Utilisation average(%)');
	title('eNodeBs PRB Utilisation variation (%)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, utilAvg);
	c = colorbar;
	c.Label.String = 'Average PRB Utilisation (%)';

	% BLER plot
	figure('Name', 'UEs BLER Average(%)');
	title('UEs BLER Average(%)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, blerAvg);
	c = colorbar;
	c.Label.String = 'Average UE BLER (%)';

	% BER plot
	figure('Name', 'UEs BER Average(%)');
	title('UEs BER Average(%)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, berAvg);
	c = colorbar;
	c.Label.String = 'Average UE BER (%)';

	% SINR plot
	figure('Name', 'UEs SINR Average(%)');
	title('UEs SINR Average(%)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, sinrAvg);
	c = colorbar;
	c.Label.String = 'Average UE SINR (dB)';

	% EVM plot
	figure('Name', 'UEs EVM Average(%)');
	title('UEs EVM Average(%)');
	xlabel('Low utilisation threshold');
	ylabel('High utilisation threshold');
	surf(utilHi, utilLo, sinrAvg);
	c = colorbar;
	c.Label.String = 'Average UE EVM (dB)';

% 	for iStation = 1: Param.numMacro + Param.numMicro
% 		hold on;
% 		y(:,1) = util(1,1,iStation, :);
% 		plot(roundx, y, ...
% 			'Color', rand(1,3),...
% 			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
% 			'Marker', char(markerStyle(randi(length(markerStyle)))),...
% 			'LineWidth', 2,...
% 			'DisplayName', strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
% 	end
% 	legend('show')
%
% 	% SINR plot
% 	figure('Name', 'UE SINR variation (db)');
% 	title('UE SINR variation (db)');
% 	xlabel('Scheduling round');
% 	ylabel('UE SINR variation (db)');
% 	for iUser = 1: Param.numUsers
% 		hold on;
% 		y(:,1) = sinr(1,1,iUser, :);
% 		plot(roundx, y, ...
% 			'Color', rand(1,3),...
% 			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
% 			'Marker', char(markerStyle(randi(length(markerStyle)))),...
% 			'LineWidth', 2,...
% 			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
% 	end
% 	legend('show')
%
% 	% CQI plot
% 	figure('Name', 'UE CQI variation');
% 	title('UE CQI variation');
% 	xlabel('Scheduling round');
% 	ylabel('UE CQI variation');
% 	for iUser = 1: Param.numUsers
% 		hold on;
% 		y(:,1) = cqi(1,1,iUser, :);
% 		plot(roundx, y, ...
% 			'Color', rand(1,3),...
% 			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
% 			'Marker', char(markerStyle(randi(length(markerStyle)))),...
% 			'LineWidth', 2,...
% 			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
% 	end
% 	legend('show')
%
% 	% SINR/CQI plot
% 	figure('Name', 'UE SINR/CQI');
% 	title('UE SINR/CQI');
% 	xlabel('UE CQI');
% 	ylabel('UE SINR');
% 	for iUser = 1: Param.numUsers
% 		hold on;
% 		x(:,1) = cqi(1,1,iUser, :);
% 		y(:,1) = sinr(1,1,iUser, :);
% 		plot(x, y, ...
% 			'Color', rand(1,3),...
% 			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
% 			'Marker', char(markerStyle(randi(length(markerStyle)))),...
% 			'LineWidth', 2,...
% 			'DisplayName', strcat('UE ', num2str(Users(iUser).UeId)));
% 	end
% 	legend('show')
%
% 	% Power plot
% 	figure('Name', 'eNodeB Power Used variation (W)');
% 	title('eNodeB Power Used variation (W)');
% 	xlabel('Scheduling round');
% 	ylabel('eNodeB Power Used variation (W)');
% 	utilLegend = '';
% 	for iStation = 1: Param.numMacro + Param.numMicro
% 		hold on;
% 		y(:,1) = power(1,1,iStation, :);
% 		plot(roundx, y, ...
% 			'Color', rand(1,3),...
% 			'LineStyle', char(lineStyle(randi(length(lineStyle)))),...
% 			'Marker', char(markerStyle(randi(length(markerStyle)))),...
% 			'LineWidth', 2,...
% 			'DisplayName', strcat('eNodeB ', num2str(Stations(iStation).NCellID)));
% 	end
% 	legend('show')

end
