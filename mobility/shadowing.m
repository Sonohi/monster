%Input 
% fc carrier frequency
% Lcorr Correaltion distance
% sigma standard deviation of the log-normal variable in dB
% v_km_h
% trace Duration

% Output
% shadowing trace in dB over distance

function [shadowing_vector] = shadowing(fc, Lcorr, sigma, v, traceDuration, TTI)

c=3e8;
lambda = c/fc;
F=4;                    % Sampling: Fraction of wavelength 
space_granularity = TTI*v;
traceDistance = traceDuration*v;

samplesLcorr=Lcorr/(lambda/F);      % No. of samples within Lcorr
samplesLcorr=round(samplesLcorr);   % Integer number: modifies slightly Lcorr
Nslowsamples=traceDistance/space_granularity/samplesLcorr;     % No of slow var. samples 
Nslowsamples=round(Nslowsamples);      % Integer number 

% Variations of sigma ==============================================

slow=randn(Nslowsamples,1);      % uncorrelated slow variations
A=(slow*sigma);         % Normal distr.: Mean M and std S  


x=[0:Nslowsamples-1]*Lcorr;     % axis in m (samples spaced Lcorr m)
x2=[0:Nslowsamples*samplesLcorr-1]*Lcorr/samplesLcorr;

shadowing_vector=interp1(x,A,x2,'spline');         % Interpolated amplitude for A 

