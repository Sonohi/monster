function displayUser(sUser,data,Param)

  
  rxpos = data(sUser).rxpos;
  txpos = data(sUser).txpos;
  

  mm = figure;
  
  set(mm, 'Position', [181 595 1.4793e+03 656]);
  
  subplot(2,4,[1,2])
  title('Overview')
  
  hold on
  for pp = 1:Param.NoStations
    plot(Param.StationPos(1,pp),Param.StationPos(2,pp),'bo','MarkerFaceColor','b')
    text(Param.StationPos(1,pp)-15,Param.StationPos(2,pp)+20,sprintf('Station %i',pp))
  end
  plot(rxpos(1),rxpos(2),'^r','MarkerFaceColor','r');
  axis(Param.Area);
  
  
  
  
  subplot(2,4,3)
  title(sprintf('User: %i',sUser));
  pos_plot = animatedline('Color','r','Marker','^','MarkerFaceColor','r','MarkerSize',3);
  hold on
  pos_plot_h = plot(txpos(1,1),txpos(2,1),'bo','MarkerFaceColor','b');
  legend(sprintf('User %i',sUser),sprintf('Station %i',data(sUser).servingStation(1)))
  hold off
  ax_pos_plot = gca;
  xlabel('X (m)')
  ylabel('Y (m)')
  
  subplot(2,4,4)
  title('Distance tx to rx')
  distance_plot = animatedline('Color','b');
  ax_distance_plot = gca;
  set(ax_distance_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.distance(1) Param.distance(2)]);
  xlabel('Round')
  ylabel('Meters')
  

  subplot(2,4,5)
  evm_plot = animatedline('Color','b');
  ax_evm_plot = gca;
  set(ax_evm_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.EVM(1) Param.EVM(2)]);
  xlabel('Round')
  ylabel('post EVM (%)')


  subplot(2,4,6)
  cqi_plot = animatedline('Color','b');
  ax_cqi_plot = gca;
  set(ax_cqi_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.CQI(1) Param.CQI(2)]);
  xlabel('Round')
  ylabel('CQI')

  subplot(2,4,7)
  yyaxis left
  snr_plot = animatedline('Color','b');
  ax_snr_plot = gca;
  set(ax_snr_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.SNR(1) Param.SNR(2)]);
  xlabel('Round')
  ylabel('SNR (dB)')
  hold on
  yyaxis right
  sinr_plot = animatedline('Color','g');
  ax_sinr_plot = gca;
  set(ax_sinr_plot,'YLim',[Param.SINR(1) Param.SINR(2)]);
  ylabel('SINR (dB)')
  legend('SNR','SINR')

  
  
  
  
  subplot(2,4,8)
  bitrate_plot = animatedline('Color','b');
  ax_bitrate_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.bitrate(1) Param.bitrate(2)],'YScale','log');
  xlabel('Round')
  ylabel('Bitrate (b/s)')
  
%   subplot(2,4,8)
%   bler_plot = animatedline('Color','b');
%   ax_bler_plot = gca;
%   set(ax_bitrate_plot,'XLim',[0 Param.no_rounds]);
%   xlabel('Round')
%   ylabel('BER')




  grid on
  for iRound = 1:Param.no_rounds
    
    
    legend(ax_pos_plot,sprintf('User %i',sUser),sprintf('Station %i',data(sUser).servingStation(iRound)));
    
    addpoints(distance_plot,iRound,data(sUser).distance(iRound));
    addpoints(pos_plot,rxpos(1,iRound),rxpos(2,iRound));
    addpoints(evm_plot,iRound,data(sUser).postEvm(iRound));
    addpoints(cqi_plot,iRound,data(sUser).cqi(iRound));
    addpoints(snr_plot,iRound,data(sUser).snr(iRound));
    addpoints(sinr_plot,iRound,real(data(sUser).sinr(iRound)));
    addpoints(bitrate_plot,iRound,data(sUser).bit_rate(iRound));
    %addpoints(bler_plot,iRound,data(sUser).ble(iRound));
    drawnow


  end
  
  

end