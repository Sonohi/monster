function [pathlossDb] = pathloss(fc,gamma,do,d)
%   PATHLOSS  is used to calculate the pathloss eNodeB - UE
%
%   Function fingerprint
%   fc		        		->  carrier frequency
%   gamma        			->  pathloss cofficients
% 												-> gamma = 4.5; % urban macrocell 3.7-6.5
%													-> gamma = 3;   % urban microcell 2.7-3.5
%													-> gamma = 2.5  % office building 1.6-3.5
%		do								->	refernce distance
%		d									->	distance eNodeB - UE
%
%   pathlossDb 				->  pathloss value in dB

	c= 3e8;
	lambda = c/fc;
	K = 20*log10(lambda/(4*pi*do));
	pathlossDb = K-10*gamma*log10(d/do);
end
