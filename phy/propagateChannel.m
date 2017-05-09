function [signal_o] = propagateChannel(param, channel, signal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Propagate signal through selected channel model.    %
%                                                                              %
%   Function fingerprint                                                       %
%   Signal  -> Modulated OFDM signal
%   Channel -> Channel configuration
%   Param   -> Struct with simulation parameters									           %
%                                                                              %
%   Signal_o  ->  signal output                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Model specific
	switch Param.channel.mode
		case 'fading'
		

		case 'mobility'
			
	end



end
