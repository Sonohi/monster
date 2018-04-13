function heff = heffCalc(d,h,hT)
% Effective transmitter height calculation
% heff = heffCalc(d,h,hT)
% where
% d - vector of distances (km) measured from the transmitter 
% h - height profile (m), i.e., height at distance d(i)
% hT - height of the transmiter antenna above ground (m)
%
% This function calculates the effective height of the transmitting/base
% antenna heff defined as its height in meters over the average level of
% the ground between distances of 3 and 15 km from the transmitting/base
% antenna, in the direction of the receiving/mobile antenna. In case the
% paths are shorter than 15 km, this function returns the height in meters
% over the terrain height averaged between 0.2d and d km (or hb) as defined
% in ITU-R P.1546-4.
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v2    03OCT14     Ivica Stevanovic, OFCOM         Use trapezoids for the average height
% v1    23AUG13     Ivica Stevanovic, OFCOM         Initial version

% check for the distance between transmitter and receiver

if (d(end)>=15)

kk = find( (d-d(1) >=3)  & (d-d(1) <=15) );
k1=kk(1);
k2=kk(end);

else
    kk=find( (d-d(1) >=0.2*d(end))  & (d-d(1) <=d(end)) );
end

x=d(kk);
y=h(kk);

%area=(x(2)-x(1))/2*y(1) + (x(end)-x(end-1))/2*y(end);
area=0;

for ii=1:length(x)-1
    area=area+ (y(ii)+y(ii+1))*(x(ii+1)-x(ii))/2;
end

hav=area/(x(end)-x(1));
hGlevel = h(1);
heff=hT+hGlevel-hav;

return