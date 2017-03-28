%Input 
% fc carrier frequency
%do refernce distance
%d distance transmitter-receiver
% gamma pathloss cofficients
%       gamma = 4.5; % urban macrocell 3.7-6.5
%       gamma = 3;   % urban microcell 2.7-3.5
%       gamma = 2.5  % office building 1.6-3.5
%       .... 
%       other gamma

%Output
%pathloss value in dB

function [pathloss_value] = pathloss(fc,gamma,do,d);

c= 3e8;
lambda = c/fc;
K = 20*log10(lambda/(4*pi*do));
pathloss_value = K-10*gamma*log10(d/do);