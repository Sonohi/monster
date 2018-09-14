function draw_winnerlayout(cfgLayout)
% Get index of stations and users
names = {cfgLayout.Stations.Name};
bsCidx = strfind(names, 'BS');
msCidx = strfind(names, 'MS');
bsIdx = not(cellfun('isempty', bsCidx));
msIdx = not(cellfun('isempty', msCidx));

% Get station positions
bsPos = [cfgLayout.Stations(bsIdx).Pos]

% Get User positions
msPos = [cfgLayout.Stations(msIdx).Pos]
msPos(:,1)
figure
hold on
for ms = 1:length(msPos)
locationMS(msPos(:,ms))
end

for bs = 1:length(bsPos(1,:))
locationBS(bsPos(:,bs))
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

function locationBS(XYZ);
plot(XYZ(1),XYZ(2),'^');
end