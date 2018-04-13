function teff1 = teff1Calc(d,h,hT,hR)
% Terrain clearance angle calculator for transmitting/base antenna
% teff1 = teff1Calc(d,h,hT,hR)
% where
% d - vector of distances (km) measured from the transmitter 
% h - height profile (m), i.e., height at distance d(i)
% hR - height of the receiver antenna above ground (m)
% hT - height of the transmitter antenna above ground (m)
%
% This function calculates the terrain clearance angle (tca) in [deg] using
% the method described in ITU-R P.1546-5 in §4.3a)
% tca is the elevation angle of the line from the transmitting/base antenna
% which just clears all the terrain obstructions over a distance of up to 15 km
% but does not go beyond the receiving/mobile antenna.
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v1    03OCT14     Ivica Stevanovic, OFCOM         Initial version

% find points that satisfy d<=15km

kk = find( d-d(1) <= 15 );

% Find all the elevation angles for the entire height profile up to 15 km

h1=h(kk);

d1=d(kk)*1000;

theta = atand((h1(2:end) - hT - h1(1))./(d1(2:end)-d(1)));

teff1 = max(theta); % in version -2 it was max(theta)-thetar

return