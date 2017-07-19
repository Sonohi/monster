load('Heatmap_17_07_MacroMicroBS_2.mat')
StationSNR = reshape([Clusters.snrVals],2,length(Clusters))

nRes = sqrt(length(Clusters));

x = 1:290/nRes:290;
y = 1:290/nRes:290;


figure

contourf(x,y,reshape(StationSNR(2,:),nRes,nRes),6)
h = colorbar
xlabel(h,'SNR (dB)')
title('Micro BS')
hold on
for ii = 2:6
plot(Stations(ii).Position(1),Stations(ii).Position(2),'ro','MarkerFaceColor','r','MarkerSize',10)
end
xlabel('Meters (x)')
ylabel('Meters (y)')


% figure
% subplot(3,2,1)
% contourf(reshape(StationSNR(1,:),nRes,nRes),5)
% colorbar
% title('Macro BS')
% 
% subplot(3,2,2)
% contourf(reshape(StationSNR(2,:),nRes,nRes),5)
% colorbar
% title('Micro BS')
% 
% 
% 
% 
% subplot(3,2,3)
% contourf(reshape(StationSNR(3,:),58,58),10)
% colorbar
% title('Micro BS 2')
% 
% subplot(3,2,4)
% contourf(reshape(StationSNR(4,:),58,58),10)
% colorbar
% title('Micro BS 3')
% 
% subplot(3,2,5)
% contourf(reshape(StationSNR(5,:),58,58),10)
% colorbar
% title('Micro BS 4')
% 
% subplot(3,2,6)
% contourf(reshape(StationSNR(6,:),58,58),10)
% colorbar
% title('Micro BS 5')
% 
% 



