function sigOut = setPower(sig,powerdBm)
% Get current power of signal
sigPwdBm = 10*log10(bandpower(sig))+30;
% Compute needed amplification/antennuation (in dB)
K = powerdBm-sigPwdBm;
sigOut = sig*sqrt(10^((K)/10));
% Check power is set
sigOutPw = 10*log10(bandpower(sigOut))+30;



end