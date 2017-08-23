function displayUser(ueOut,Users,sUser,Param)

  user = Users(sUser);
  
  positions = [ueOut(1,1,:,sUser).rxPosition];
  txpositions = [ueOut(1,1,:,sUser).txPosition];
  xx = positions(1:3:end);
  yy = positions(2:3:end);
  zz = positions(3:3:end);
  xx_tx = txpositions(1:3:end);
  yy_tx = txpositions(2:3:end);
  zz_tx = txpositions(3:3:end);
  
  

  postEvm = [ueOut(1,1,:,sUser).postEvm];
  EVM_min = 0;
  EVM_max = 100;
  
  cqi = [ueOut(1,1,:,sUser).cqi];
  cqi_min = 0;
  cqi_max = 15;
  
  snr = [ueOut(1,1,:,sUser).snr];
  sinr = [ueOut(1,1,:,sUser).sinr];
  err_blocks = 0;
  for iRound = 1:Param.no_rounds
    blocks = [ueOut(1,1,iRound,sUser).blocks];
    bits = [ueOut(1,1,iRound,sUser).bits];
    bit_rate(iRound) = bits.tot/Param.round_duration;
    bler(iRound) =  blocks.err/Param.round_duration;
    ber(iRound) = bits.err/Param.round_duration;
    distance(iRound) = sqrt((xx_tx(iRound)-xx(iRound)).^2+(yy_tx(iRound)-yy(iRound)).^2+(zz_tx(iRound)-zz(iRound)).^2);

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
  evm_plot = animatedline('Color','b');
  ax_evm_plot = gca;
  set(ax_evm_plot,'XLim',[0 Param.no_rounds],'YLim',[min(EVM_min) max(EVM_max)]);
  xlabel('Round')
  ylabel('post EVM (%)')


  subplot(2,4,5)
  cqi_plot = animatedline('Color','b');
  ax_cqi_plot = gca;
  set(ax_cqi_plot,'XLim',[0 Param.no_rounds],'YLim',[cqi_min cqi_max]);
  xlabel('Round')
  ylabel('CQI')

  subplot(2,4,6)
  yyaxis left
  snr_plot = animatedline('Color','b');
  ax_snr_plot = gca;
  set(ax_snr_plot,'XLim',[0 Param.no_rounds],'YLim',[min(snr) max(snr)]);
  xlabel('Round')
  ylabel('SNR (dB)')
  hold on
  yyaxis right
  sinr_plot = animatedline('Color','g');
  ax_sinr_plot = gca;
  set(ax_sinr_plot,'YLim',[min(sinr) max(sinr)]);
  ylabel('SINR (dB)')
  legend('SNR','SINR')

  
  
  
  
  subplot(2,4,7)
  bitrate_plot = animatedline('Color','b');
  ax_bitrate_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds],'YLim',[min_bitrate max_bitrate]);
  xlabel('Round')
  ylabel('Bitrate (b/s)')
  
  subplot(2,4,8)
  bler_plot = animatedline('Color','b');
  ax_bler_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds]);
  xlabel('Round')
  ylabel('BER')




  grid on
  for iRound = 1:length(xx)-1e
    addpoints(pos_plot,xx(iRound),yy(iRound));
    addpoints(evm_plot,iRound,postEvm(iRound));
    addpoints(cqi_plot,iRound,cqi(iRound));
    addpoints(snr_plot,iRound,snr(iRound));
    addpoints(sinr_plot,iRound,sinr(iRound));
    addpoints(bitrate_plot,iRound,bit_rate(iRound));
    addpoints(bler_plot,iRound,ber(iRound));
    drawnow


  end
  
  

end