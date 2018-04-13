function h = plotTeff1(ax,d,h,hT,teff1)
% Plot the  line that clears all obstractions defined by terrain clearance
% angle as in ITU-R P.1546-5 §4.3a)
% h = plotTeff1(ax,d,h,hT,teff1)
% where
% d - vector of distances (km) measured from the transmitter 
% h - height profile (m), i.e., height at distance d(i)
% hT - height of the transmitter antenna above ground (m) (at position d(1))
% teff1 - terrain clearance angle
% 
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v1    03OCT14     Ivica Stevanovic, OFCOM         Initial version

% find points that satisfy d<=15km

kk = find( d-d(1) <= 15 );

% Find all the elevation angles for the entire height profile

x1=d(kk(1));   % transmitter position
x2=d(kk(end)); % 15 km distance from the transmitter
y1=h(1)+hT;
y2=h(1)+hT+(x2-x1)*1000*tand(teff1);

color=[0.5 0.5 0.5];
% draw the lines
% horizontal
plot(ax,[x1 x2],[y1 y1],'Color',color);
plot(ax,[x1 x2], [y1 y2],'Color',color);

return