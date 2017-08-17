function displayUser(ueOut,Users,sUser,Param)

  user = Users(sUser);
  
  positions = [ueOut(1,1,:,sUser).rxPosition];
  xx = positions(1:3:end);
  yy = positions(2:3:end);

  postEvm = [ueOut(1,1,:,sUser).postEvm];
  EVM_min = 0;
  EVM_max = 100;
  
  cqi = [ueOut(1,1,:,sUser).cqi];
  cqi_min = 0;
  cqi_max = 15;
  
  snr = [ueOut(1,1,:,sUser).snr];
  sinr = [ueOut(1,1,:,sUser).sinr];
  
  for iRound = 1:Param.no_rounds
    bits = [ueOut(1,1,iRound,sUser).bits];
    if iRound == 1
      total_bits(iRound) = sum([bits.tot]);
    else
      total_bits(iRound) = sum([bits.tot])-sum(total_bits(1:iRound-1));
    end
    bit_rate(iRound) = total_bits(iRound)/Param.round_duration;

  end
  min_bitrate = 0;
  max_bitrate = 10e6;


  figure
  set(gcf, 'Position', [181 595 1.4793e+03 656])
  title(sprintf('User: %i',sUser));

  var_p = 0.01;
  subplot(2,4,[1,3])
  pos_plot = animatedline('Color','r','Marker','o','MarkerSize',3);
  ax_pos_plot = gca;
  set(ax_pos_plot,'XLim',[min(xx)-var_p max(xx)+var_p],'YLim',[min(yy)-var_p max(yy)+var_p]);
  xlabel('X (m)')
  ylabel('Y (m)')

  subplot(2,4,4)
  evm_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
  ax_evm_plot = gca;
  set(ax_evm_plot,'XLim',[0 Param.no_rounds],'YLim',[min(EVM_min) max(EVM_max)]);
  xlabel('Round')
  ylabel('post EVM (%)')


  subplot(2,4,5)
  cqi_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
  ax_cqi_plot = gca;
  set(ax_cqi_plot,'XLim',[0 Param.no_rounds],'YLim',[cqi_min cqi_max]);
  xlabel('Round')
  ylabel('CQI')

  subplot(2,4,6)
  yyaxis left
  snr_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
  ax_snr_plot = gca;
  set(ax_snr_plot,'XLim',[0 Param.no_rounds],'YLim',[min(snr) max(snr)]);
  xlabel('Round')
  ylabel('SNR (dB)')
  hold on
  yyaxis right
  sinr_plot = animatedline('Color','g','Marker','o','MarkerSize',7,'MarkerFaceColor','g');
  ax_sinr_plot = gca;
  set(ax_sinr_plot,'YLim',[min(sinr) max(sinr)]);
  ylabel('SINR (dB)')

  
  
  
  
  subplot(2,4,7)
  bitrate_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
  ax_bitrate_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds],'YLim',[min_bitrate max_bitrate]);
  xlabel('Round')
  ylabel('Bitrate (b/s)')




  grid on
  for iRound = 1:length(xx)-1
    addpoints(pos_plot,xx(iRound),yy(iRound));
    addpoints(evm_plot,iRound,postEvm(iRound));
    addpoints(cqi_plot,iRound,cqi(iRound));
    addpoints(snr_plot,iRound,snr(iRound));
    addpoints(sinr_plot,iRound,sinr(iRound));
    addpoints(bitrate_plot,iRound,bit_rate(iRound));
    drawnow
    pause(0.1)

  end


end