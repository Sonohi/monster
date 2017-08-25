function displayUser(sUser,data,Param)

  
  rxpos = data(sUser).rxpos;
  

  figure
  set(gcf, 'Position', [181 595 1.4793e+03 656])
  title(sprintf('User: %i',sUser));

  var_p = 0.01;
  subplot(2,4,[1,3])
  pos_plot = animatedline('Color','r','Marker','o','MarkerSize',3);
  ax_pos_plot = gca;
  set(ax_pos_plot,'XLim',[min(rxpos(1,:))-var_p max(rxpos(1,:))+var_p],'YLim',[min(rxpos(2,:))-var_p max(rxpos(2,:))+var_p]);
  xlabel('X (m)')
  ylabel('Y (m)')

  subplot(2,4,4)
  evm_plot = animatedline('Color','b');
  ax_evm_plot = gca;
  set(ax_evm_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.EVM(1) Param.EVM(2)]);
  xlabel('Round')
  ylabel('post EVM (%)')


  subplot(2,4,5)
  cqi_plot = animatedline('Color','b');
  ax_cqi_plot = gca;
  set(ax_cqi_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.CQI(1) Param.CQI(2)]);
  xlabel('Round')
  ylabel('CQI')

  subplot(2,4,6)
  yyaxis left
  snr_plot = animatedline('Color','b');
  ax_snr_plot = gca;
  set(ax_snr_plot,'XLim',[0 Param.no_rounds],'YLim',[min(data(sUser).snr) max(data(sUser).snr)]);
  xlabel('Round')
  ylabel('SNR (dB)')
  hold on
  yyaxis right
  sinr_plot = animatedline('Color','g');
  ax_sinr_plot = gca;
  set(ax_sinr_plot,'YLim',[min(real(data(sUser).sinr)) max(real(data(sUser).sinr))]);
  ylabel('SINR (dB)')
  legend('SNR','SINR')

  
  
  
  
  subplot(2,4,7)
  bitrate_plot = animatedline('Color','b');
  ax_bitrate_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds],'YLim',[Param.bitrate(1) Param.bitrate(2)]);
  xlabel('Round')
  ylabel('Bitrate (b/s)')
  
  subplot(2,4,8)
  bler_plot = animatedline('Color','b');
  ax_bler_plot = gca;
  set(ax_bitrate_plot,'XLim',[0 Param.no_rounds]);
  xlabel('Round')
  ylabel('BER')




  grid on
  for iRound = 1:Param.no_rounds
    addpoints(pos_plot,rxpos(1,iRound),rxpos(2,iRound));
    addpoints(evm_plot,iRound,data(sUser).postEvm(iRound));
    addpoints(cqi_plot,iRound,data(sUser).cqi(iRound));
    addpoints(snr_plot,iRound,data(sUser).snr(iRound));
    addpoints(sinr_plot,iRound,real(data(sUser).sinr(iRound)));
    addpoints(bitrate_plot,iRound,data(sUser).bit_rate(iRound));
    addpoints(bler_plot,iRound,data(sUser).ble(iRound));
    drawnow


  end
  
  

end