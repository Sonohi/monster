function displayStation(enbOut,Stations,sStation,Param,ueOut,Users)

station = Stations(sStation);
p = 1;
for ll = 1:length(Stations)
  if Stations(ll).NCellID ~= station.NCellID
    xx_unused(p) =  Stations(ll).Position(1);
    yy_unused(p) =  Stations(ll).Position(2);
    p = p +1;
  end
end

xx = station.Position(1);
yy = station.Position(2);

utility = [enbOut(1,1,:,sStation).util];
power = [enbOut(1,1,:,sStation).power];

utility_min = 0;
utility_max = 100;

power_min = 0;
power_max = 100;

for ll = 1:Param.no_rounds
  schedule = [enbOut(1,1,ll,sStation).schedule];
  schedule_ueid = [schedule.UeId];
  uniques_list{ll} = unique(schedule_ueid(schedule_ueid ~= 0));
  for sUser = 1:length(uniques_list{ll})
    bits = [ueOut(1,1,ll,sUser).bits];
    bit_rate(ll,sUser) = bits.tot/Param.round_duration;
  end
end
min_bitrate = 0;
max_bitrate = 10e8;

scheduled_users = cellfun(@unique, uniques_list, 'UniformOutput', false);

figure
set(gcf, 'Position', [181 595 1.4793e+03 656])


%% Position plot
subplot(2,4,[1,3])
hold on
for ll = 1:length(scheduled_users{1})
  users = Users(scheduled_users{1});
  plot([xx users(ll).Position(1)],[yy users(ll).Position(2)],'--o')
end
plot(xx,yy,'Color','r','Marker','o','MarkerFaceColor','r','MarkerSize',8)
for ll = 1:length(Stations)-1
  plot(xx_unused(ll),yy_unused(ll),'Color','k','Marker','o','MarkerFaceColor','k','MarkerSize',8)
end
ax_pos_plot = gca;
set(ax_pos_plot,'XLim',[0 290],'YLim',[0 290]);
xlabel('X (m)')
ylabel('Y (m)')


%% Utility
subplot(2,4,4)
utility_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_utility_plot = gca;
set(ax_utility_plot,'XLim',[0 Param.no_rounds],'YLim',[min(utility_min) max(utility_max)]);
xlabel('Round')
ylabel('Utility (%)')

%% Power
subplot(2,4,5)
power_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_power_plot = gca;
set(ax_power_plot,'XLim',[0 Param.no_rounds],'YLim',[min(power_min) max(power_max)]);
xlabel('Round')
ylabel('Power (W)')

%% Aggregated bitrate
subplot(2,4,6)
bitrate_agg_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_bitrate_plot = gca;
set(ax_bitrate_plot,'XLim',[0 Param.no_rounds],'YLim',[min(min_bitrate) max(max_bitrate)],'YScale','log');
xlabel('Round')
ylabel('Agg. Bitrate DL')

%% Number of users.
subplot(2,4,7)
users_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_users_plot = gca;
set(ax_users_plot,'XLim',[0 Param.no_rounds],'YLim',[0 length(ueOut(1,1,1,:))]);
xlabel('Round')
ylabel('Users scheduled')

grid on
for iRound = 1:Param.no_rounds
  addpoints(utility_plot,iRound,utility(iRound));
  addpoints(power_plot,iRound,power(iRound));
  addpoints(bitrate_agg_plot,iRound,sum(bit_rate(iRound,:)))
  addpoints(users_plot,iRound,length(scheduled_users{iRound}))
  
  %% Update position plot
  delete(ax_pos_plot)
  subplot(2,4,[1,3])
  hold on
  for ll = 1:length(scheduled_users{iRound})
    users = Users(scheduled_users{iRound});
    plot([xx users(ll).Position(1)],[yy users(ll).Position(2)],'--o')
  end
  plot(xx,yy,'Color','r','Marker','o','MarkerFaceColor','r','MarkerSize',8)
  for ll = 1:length(Stations)-1
    plot(xx_unused(ll),yy_unused(ll),'Color','k','Marker','o','MarkerFaceColor','k','MarkerSize',8)
  end
  ax_pos_plot = gca;
  set(ax_pos_plot,'XLim',[0 290],'YLim',[0 290]);
  xlabel('X (m)')
  ylabel('Y (m)')
  drawnow
end



end


