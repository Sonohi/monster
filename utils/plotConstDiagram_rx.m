function [ h ] = plotConstDiagram_rx(Users)

            h = figure(2);
            set(h,'Position',[425 425 900 900]);
            
            for pp = 1:length(Users)
                hs(pp)=subplot(5,3,pp);
                dims = size(Users(pp).RxSubFrame);
                sps = 1;
                if dims ~= [0 0]
                    est_SubFrame = reshape(Users(pp).RxSubFrame,length(Users(pp).RxSubFrame(:,1))*length(Users(pp).RxSubFrame(1,:)),1);
                    plot(est_SubFrame,'.')
                    title(['Received resource grid for User: ',num2str(pp)],'Fontsize',8);
                    ylabel('Quadrature');
                    xlabel('Inphase');
                    set(hs(pp),'FontSize',8);
 
                end
                
            end

end