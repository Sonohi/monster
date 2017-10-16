classdef BSReceiverModule
	properties
		NoiseFigure;
		Waveform;
	end

	methods

		function obj = BSReceiverModule(Param)
			obj.NoiseFigure = Param.bsNoiseFigure;
		end

		function obj = set.Waveform(obj,Sig)
			if isempty(obj.Waveform)
				obj.Waveform = Sig;
			else
				obj.Waveform = obj.Waveform + Sig;
			end
		end


	end



end
