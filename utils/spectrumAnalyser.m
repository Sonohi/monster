function [] = spectrumAnalyser(samplingRate, waveform)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   SPECTRUM ANALYSER  is used to generate a cool fig of a OFDM waveform			 %
%                                                                              %
%   Function fingerprint                                                       %
%   samplingRate  			->  sampling rate	                                     %
%   waveform   					->  waveform																		       %
%                                                                              %                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	spectrumPlotTx = dsp.SpectrumAnalyzer;
	spectrumPlotTx.SampleRate = samplingRate;
	spectrumPlotTx.SpectrumType = 'Power density';
	spectrumPlotTx.PowerUnits =  'dBm';
	spectrumPlotTx.RBWSource = 'Property';
	spectrumPlotTx.RBW = 15e3;
	spectrumPlotTx.FrequencySpan = 'Span and center frequency';
	spectrumPlotTx.Span = 7.68e6;
	spectrumPlotTx.CenterFrequency = 0;
	spectrumPlotTx.Window = 'Rectangular';
	spectrumPlotTx.SpectralAverages = 10;
	spectrumPlotTx.YLimits = [-100 -60];
	spectrumPlotTx.YLabel = 'PSD';
	spectrumPlotTx.Title = 'Test Model E-TM1.1, 5 MHz Signal Spectrum';
	spectrumPlotTx.ShowLegend = false;
	spectrumPlotTx(waveform);
end
