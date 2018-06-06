function r = fresnel_zone(n, d1, d2, f)
% Computes the nth fresnel zone radius.
%
% :param d1: distance to point from transmitter, given in meters
% :param d2: distance to point from receiver, given in meters
% :param f: Frequency of transmission, given in Hz.
lambda = 299792458/f;
r = sqrt((n*lambda*d1*d2)/(d1+d2));
end