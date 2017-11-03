classdef enbReceiverModule
	properties
		NoiseFigure;
		Waveform;
	end

	methods

		function obj = enbReceiverModule(Param)
			obj.NoiseFigure = Param.bsNoiseFigure;
		end

		function obj = set.Waveform(obj,Sig)
			obj.Waveform = Sig;
		end

		function [returnCode, obj] = demodulate(obj,ueObj)
			% TODO: validate that a waveform exist.
			ue = cast2Struct(ueObj);
			Subframe = lteSCFDMADemodulate(ue, obj.Waveform);

			if all(Subframe(:) == 0)
				returnCode = 0;
			else
				obj.Subframe = Subframe; 
				returnCode = 1;
			end

		end


	end



end
