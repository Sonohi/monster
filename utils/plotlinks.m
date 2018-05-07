function plotlinks(Users, Stations, LayoutPlot, chtype)

% If the links have been added before, delete them
h_scheduled = findobj(LayoutPlot,'Tag','ScheduledLinks');
if ~isempty(h_scheduled)
    delete(h_scheduled)
end

h_associated = findobj(LayoutPlot,'Tag','AssociatedLinks');

if ~isempty(h_associated)
    delete(h_associated)
end

for station_idx = 1:length(Stations)
  station = Stations(station_idx);
  tx_pos = station.Position;
  % Plot all scheduled users 
  switch chtype
    case 'downlink'
      scheduledusers = [station.ScheduleDL.UeId];
      scheduledusers = unique(scheduledusers(scheduledusers ~= -1));
    case 'uplink'
      scheduledusers = [station.ScheduleUL.UeId];
      scheduledusers = unique(scheduledusers(scheduledusers ~= -1));
  end
  for user = 1:length(scheduledusers)
    rx_obj = Users(find([Users.NCellID] == scheduledusers(user)));
    rx_pos = rx_obj.Position;
    h_scheduled = plot(LayoutPlot, [tx_pos(1), rx_pos(1)], [tx_pos(2), rx_pos(2)],'k:', 'linewidth',3, 'DisplayName', strcat('BS ', num2str(station.NCellID),'-> UE ', num2str(rx_obj.NCellID),' (scheduled)'), 'Tag','ScheduledLinks');
  end
  
  % Plot all associated users (available in Users)
  associatedusers = [station.Users.UeId];
  associatedusers = associatedusers(associatedusers ~= -1);
  if ~isempty(associatedusers)
    associatedusers = associatedusers(~ismember(associatedusers,scheduledusers));
    for user = 1:length(associatedusers)
      rx_obj = Users(find([Users.NCellID] == associatedusers(user)));
      rx_pos = rx_obj.Position;
      h_associated = plot(LayoutPlot, [tx_pos(1), rx_pos(1)], [tx_pos(2), rx_pos(2)],'k--',  'DisplayName', strcat('BS ', num2str(station.NCellID),'-> UE ', num2str(rx_obj.NCellID)),'Tag', 'AssociatedLinks');
    end
  end
  
  
end

drawnow
end