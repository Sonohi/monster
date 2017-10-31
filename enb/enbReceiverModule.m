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
			if isempty(obj.Waveform)
				obj.Waveform = Sig;
			else
				obj.Waveform = obj.Waveform + Sig;
			end
		end

		function [returnCode, obj] = demod(obj,ueObj)
			% TODO: validate that a waveform exist.
			ue = cast2Struct(ueObj);
			Subframe = lteSCFDMADemodulate(ue, obj.Waveform); %#ok

			if all(Subframe(:) == 0) %#ok
				returnCode = 0;
			else
				obj.Subframe = Subframe; %#ok
				returnCode = 1;
			end

		end


	end



end
