load('Heatmap_17_07_MacroMicroBS_2.mat')
StationSNR = reshape([Clusters.snrVals],2,length(Clusters))

nRes = sqrt(length(Clusters));


figure
subplot(3,2,1)
contourf(reshape(StationSNR(1,:),nRes,nRes),10)
colorbar
title('Macro BS')

subplot(3,2,2)
contourf(reshape(StationSNR(2,:),5,5),10)
colorbar
title('Micro BS')

subplot(3,2,3)
contourf(reshape(StationSNR(3,:),58,58),10)
colorbar
title('Micro BS 2')

subplot(3,2,4)
contourf(reshape(StationSNR(4,:),58,58),10)
colorbar
title('Micro BS 3')

subplot(3,2,5)
contourf(reshape(StationSNR(5,:),58,58),10)
colorbar
title('Micro BS 4')

subplot(3,2,6)
contourf(reshape(StationSNR(6,:),58,58),10)
colorbar
title('Micro BS 5')





