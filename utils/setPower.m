function sigOut = setPower(sig,power)
% Get current power of signal
sigPw = 10*log10(bandpower(sig))+30;
% Compute needed amplification/antennuation
K = power-sigPw;
sigOut = sig*sqrt(10^((K)/10));
% Check power is set
sigOutPw = 10*log10(bandpower(sigOut))+30;

end