function sigOut = setPower(sig,powerdBm)
	bandPowerIn = bandpower(sig);
	if length(bandPowerIn) > 1
		sigPowerIn = bandPowerIn(1);
	else
		sigPowerIn = bandPowerIn;
	end
	% Get current power of signal
	sigPwdBm = 10*log10(sigPowerIn)+30;
	% Compute needed amplification/antennuation (in dB)
	K = powerdBm-sigPwdBm;
	sigOut = sig*sqrt(10^((K)/10));
	bandPowerOut = bandpower(sigOut);
	if length(bandPowerOut) > 1
		sigPowerOut = bandPowerOut(1);
	else
		sigPowerOut = bandPowerOut;
	end
	% Check power is set
	sigOutPw = 10*log10(sigPowerOut)+30;
end