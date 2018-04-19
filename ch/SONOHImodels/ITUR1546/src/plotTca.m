function h = plotTca(ax,d,h,hR,tca)
% Plot the  line that clears all obstractions defined by terrain clearance
% angle as in ITU-R P.1546-4 definition
% h = plotTca(ax,d,h,hR,tca)
% where
% ax - current axes
% d - vector of distances (km) measured from the transmitter 
% h - height profile (m), i.e., height at distance d(i)
% hR - height of the receiver antenna above ground (m) (at position d(end))
% tca - terrain clearance angle
% 
%
% Rev   Date        Author                          Description
%-------------------------------------------------------------------------------
% v1    23AUG13     Ivica Stevanovic, OFCOM         Initial version

% find points that satisfy d<=16km

kk = find( d(end)-d <= 16 );

% Find all the elevation angles for the entire height profile

x1=d(kk(1));   % 16 km distance from the receiver (or transmitter position)
x2=d(kk(end)); %receiver position
y1=h(end)+hR+(x2-x1)*1000*tand(tca);
y2=h(end)+hR;
cOlor=[0.5 0.5 0.5];
% draw the lines
% horizontal
plot(ax,[x1 x2],[y2 y2],'Color',cOlor);
plot(ax,[x1 x2], [y1 y2],'Color',cOlor);

return