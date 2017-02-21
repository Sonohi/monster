%Input
% fc = carrier frequency
% v_km_h = user speed
% numRBs number of resource block
% traceDuration
% scenario = 1 --> pedestrianEPA 2--> vehicularEVA, 3 --> urbanETU

%output
% fast fading values in dB, the coherence time is fixed to 0.0005


function [fast_fading_vector] = fast_fading(fc, v, numRBs, traceDuration, scenario, TTI);

c = 3e8; 

% Excess taps delay (according to 3GPP TS 36.104 Annex B.2)
delays_pedestrianEPA = [0 30e-9 70e-9 90e-9 120e-9 190e-9 410e-9];
delays_vehicularEVA = [0 30e-9 150e-9 310e-9 370e-9 710e-9 1090e-9 1730e-9 2510e-9];
delays_urbanETU = [0 50e-9 120e-9 200e-9 230e-9 500e-9 1600e-9 2300e-9 5000e-9];
% Realtive power of taps (according to 3GPP TS 36.104 Annex B.2)
power_pedestrianEPA = [0.0 -1.0 -2.0 -3.0 -8.0 -17.2 -20.8];
power_vehicularEVA = [0.0 -1.5 -1.4 -3.6 -0.6 -9.1 -7.0 -12.0 -16.9];
power_urbanETU = [-1.0 -1.0 -1.0 0.0 0.0 0.0 -3.0 -5.0 -7.0];

lambda = c/fc;
fd = v / lambda; % doppler shift


% when working with an FFT, the normalized frequency w is
% w = 2 * pi * (f/fs) * t
% hence the max normalized frequency w=2*pi corresponds to f = fs,
% hence fs is also the max frequecy of our PowerSpectralDensity
fs = 20e6; 
% sampling period must be determined corresponding to the sampling
% frequency, because of the properties of an FFT
% in other words, if ts = 1/fs, then the samples of the FFT will be
% spaced by fs (which is what we want)
ts = 1/fs; % sampling period (i.e., 1 subframe duration)


% create the channel object
if scenario==1
c = rayleighchan(ts, fd, delays_pedestrianEPA, power_pedestrianEPA);
elseif scenario == 2
c = rayleighchan(ts, fd, delays_vehicularEVA, power_vehicularEVA);
elseif scenario == 3
c = rayleighchan(ts, fd, delays_urbanETU, power_urbanETU);
else
    disp('Error!!');
end 
    

%c.StorePathGains = 1;
c.ResetBeforeFiltering = 0;
c.NormalizePathGains = 1;


% number of samples of one channel realization
numSamples = TTI / ts;

% total trace duration in s



sig = zeros(numSamples, 1); % Signal
sig(1) = 1; % dirac impulse

[psdsig,F] = pwelch(sig,[],[],numRBs,fs,'twosided');  

tic;

for ii=1:round((traceDuration/TTI))
    if(mod(ii,100)==0)
    ii
    toc
    tic;
    end
    % y is the frequency response of the channel
    y = filter(c,sig);   
    
%     [Pxx,F] = PWELCH(X,WINDOW,NOVERLAP,NFFT,Fs) returns a PSD computed as
%     a function of physical frequency (Hz).  Fs is the sampling frequency
%     specified in Hz.  If Fs is empty, it defaults to 1 Hz.
%  
%     F is the vector of frequencies at which the PSD is estimated and has
%     units of Hz.  For real signals, F spans the interval [0,Fs/2] when NFFT
%     is even and [0,Fs/2) when NFFT is odd.  For complex signals, F always
%     spans the interval [0,Fs).


    [psdy,F] = pwelch(y,[],[],numRBs,fs);      
    
    %% the gain in frequency is obtained by dividing the psd of the received signal
    %% by the psd of the original signal. Note that the psd of the original
    %% signal is constant in frequency (since the transform of a delta is a
    %% constant)
    ppssdd(:,ii) = psdy ./ psdsig;  
    

    % this to plot
    %   figure;
    %    PWELCH(y,[],[],numRBs,fs);

    % alternative plot
    %figure;
    %plot(F, 10.*log10(ppssdd(:,ii)));
end


fast_fading_vector = 10*log10(ppssdd);
 
