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
end
