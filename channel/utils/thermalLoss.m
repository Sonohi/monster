	function [lossdBm, thermalNoise] = thermalLoss(varargin)
		% Compute thermal loss based on bandwidth, at T = 290 K.
		% Bandwidth is either given as MHz, or a waveform is supplied with the sampling rate.
		% Worst case given by the number of resource blocks. Bandwidth is
		% given based on the waveform. Computed using matlabs :obj:`obw`
		%
		% :param obj:
		% :returns lossdBm:
		% :returns thermalNoise:
		if length(varargin) == 1
			bw = varargin{1}; 
		elseif length(varargin) > 1
			RxWaveform = varargin{1};
			RxWaveformSamplingRate = varargin{2};
			bw = obw(RxWaveform, RxWaveformSamplingRate);
		else
			bw = 20e6; % Full bandwidth
		end
		
		T = 290;
		k = physconst('Boltzmann');
		thermalNoise = k*T*bw;
		lossdBm = 10*log10(thermalNoise*1000);
	end