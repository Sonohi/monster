clear all
close all

%% Select user to play back


ue = 5;

load('results/utilLo_1-utilHi_100.mat')


positions = [ueResults(:,ue).rxPosition];
postEvm = [ueResults(:,ue).postEvm];
cqi = [ueResults(:,ue).cqi];
snr = [ueResults(:,ue).snr];

xx = positions(1:3:end);
yy = positions(2:3:end);

figure
set(gcf, 'Position', [181 595 1.4793e+03 656])

var_p = 0.01;
subplot(2,3,[1,3])
pos_plot = animatedline('Color','r','Marker','o','MarkerSize',3);
ax_pos_plot = gca;
set(ax_pos_plot,'XLim',[min(xx)-var_p max(xx)+var_p],'YLim',[min(yy)-var_p max(yy)+var_p]);
xlabel('X (m)');
ylabel('Y (m)');

subplot(2,3,4);
evm_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_evm_plot = gca;
set(ax_evm_plot,'XLim',[0 20],'YLim',[min(postEvm) max(postEvm)]);
xlabel('Round');
ylabel('post EVM (%)');


subplot(2,3,5)
cqi_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_cqi_plot = gca;
set(ax_cqi_plot,'XLim',[0 20],'YLim',[min(cqi) max(cqi)]);
xlabel('Round')
ylabel('CQI')

subplot(2,3,6)
snr_plot = animatedline('Color','b','Marker','x','MarkerSize',7);
ax_snr_plot = gca;
set(ax_snr_plot,'XLim',[0 20],'YLim',[min(snr) max(snr)]);
xlabel('Round')
ylabel('SNR (dB)')



grid on
for iRound = 1:length(xx)-1;
  addpoints(pos_plot,xx(iRound),yy(iRound));
  addpoints(evm_plot,iRound,postEvm(iRound));
  addpoints(cqi_plot,iRound,cqi(iRound));
  addpoints(snr_plot,iRound,snr(iRound));
  drawnow
  pause(0.2)
  
end





