function [ h ] = plotReGrids(Users)
            h = figure(3);
            set(h,'Position',[425 425 900 900]);
            
            for pp = 1:length(Users)
                hs(pp)=subplot(5,3,pp);
                dims = size(Users(pp).RxSubFrame);
                if dims ~= [0 0]
                    surf(20*log10(abs(Users(pp).RxSubFrame)));
                    title(['Received resource grid for User: ',num2str(pp)],'Fontsize',8);
                    ylabel('Subcarrier');
                    xlabel('Symbol');
                    zlabel('absolute value (dB)');
                    axis([1 dims(2) 1 dims(1) -40 10]);
                    set(hs(pp),'FontSize',8);
                else

                end
            end

end

