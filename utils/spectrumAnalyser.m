function [spectrumPlotTx] = spectrumAnalyser(sig, Fs)

%   SPECTRUM ANALYSER  is used to generate a cool fig of a OFDM waveform
%
%   Function fingerprint
%   samplingRate  			->  sampling rate
%   waveform   					->  waveform																		                                                                                     %

	spectrumPlotTx = dsp.SpectrumAnalyzer;
	spectrumPlotTx.SampleRate = Fs;
	spectrumPlotTx.SpectrumType = 'Power density';
	spectrumPlotTx.PowerUnits =  'dBm';
	spectrumPlotTx.RBWSource = 'Property';
	spectrumPlotTx.RBW = 15e3;
	spectrumPlotTx.Span = 7.68e6;
	spectrumPlotTx.CenterFrequency = 0;
	spectrumPlotTx.Window = 'Rectangular';
	spectrumPlotTx.SpectralAverages = 10;
	spectrumPlotTx.YLimits = [-100 -60];
	spectrumPlotTx.YLabel = 'PSD';
	spectrumPlotTx.ShowLegend = true;
	spectrumPlotTx(sig);
end
