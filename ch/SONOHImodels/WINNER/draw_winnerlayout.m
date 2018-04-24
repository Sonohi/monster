function draw_winnerlayout(cfgLayout)
% Get index of stations and users
names = {cfgLayout.Stations.Name};
bs_cidx = strfind(names, 'BS');
ms_cidx = strfind(names, 'MS');
bs_idx = not(cellfun('isempty', bs_cidx));
ms_idx = not(cellfun('isempty', ms_cidx));

% Get station positions
bs_pos = [cfgLayout.Stations(bs_idx).Pos]

% Get User positions
ms_pos = [cfgLayout.Stations(ms_idx).Pos]
ms_pos(:,1)
figure
hold on
for ms = 1:length(ms_pos)
locationMS(ms_pos(:,ms))
end

for bs = 1:length(bs_pos(1,:))
locationBS(bs_pos(:,bs))
end

drawlinks([cfgLayout.Stations.Pos],cfgLayout.Pairing)


end

function drawlinks(positions,pairing)

for pair = 1:length(pairing(1,:))
  tx = positions(1:2,pairing(1,pair))
  rx = positions(1:2,pairing(2,pair))
  
  plot([tx(1), rx(1)],[tx(2), rx(2)],'-')
end

end


function locationMS(XYZ)
plot(XYZ(1),XYZ(2),'o');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A function that draws the location of Bs
function locationBS(XYZ);
plot(XYZ(1),XYZ(2),'^');
end