function tca = tcaCalc(d,h,hR,hT)
% Terrain clearance angle calculator
% tca = tcaCalc(d,h)
% where
% d - vector of distances (km) measured from the transmitter 
% h - height profile (m), i.e., height at distance d(i)
% hR - height of the receiver antenna above ground (m)
% hT - height of the transmitter antenna above ground (m)
%
% This function calculates the terrain clearance angle (tca) in [deg] using
% the method described in ITU-R P.1546-5
% tca is the elevation angle of the line from the receiving/mobile antenna
% which just clears all the terrain obstructions over a distance of up to 16 km
% but does not go beyond the transmitting/base antenna.
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v2    06SEP13     Ivica Stevanovic, OFCOM         Modified to account for
%                                                   hTx
% v1    22AUG13     Ivica Stevanovic, OFCOM         Initial version

% find points that satisfy d<=16km

kk = find( d(end)-d <= 16 );

% Find all the elevation angles for the entire height profile up to 16 km

h1=h(kk);
d1=d(kk)*1000;

theta = atand((h1(1:end-1) - hR - h1(end))./(d1(end)-d1(1:end-1)));

% Find the elevation angle of the transmitter

thetar = atand( (h(1)+hT- hR - h(end))/(1000*(d(end)-d(1))) );

% are there any obstructions within up to 16 km from the receiver

%if (max(theta) < thetar) % there is no obstruction in the direction of transmitter antenna
%    tca=0;
%else
    tca = max(theta); % in version -2 it was max(theta)-thetar
%end
return
