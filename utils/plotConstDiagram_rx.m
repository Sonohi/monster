function [ h1, h2 ] = plotConstDiagram_rx(Stations,Users)
           
            
            h1 = figure('Name', 'Rx constellation');
            set(h1,'Position',[425 425 900 900],'WindowStyle','Docked');
            
            for pp = 1:length(Users)
                hs(pp)=subplot(5,3,pp);
                dims = size(Users(pp).Rx.Subframe);
                sps = 1;
                if dims ~= [0 0]
                    iServingStation = find([Stations.NCellID] == Users(pp).NCellID);
                    [indPdsch, info] = Stations(iServingStation).getPDSCHindicies;
                    est_SubFrame = Users(pp).Rx.Subframe(indPdsch);
                    plot(est_SubFrame,'.')
                    title(['User: ',num2str(pp)],'Fontsize',8);
                    ylabel('Quadrature');
                    xlabel('Inphase');
                    set(hs(pp),'FontSize',8);
 
                end
                
            end
            
            
            h2 = figure('Name', 'Eq constellation');
            set(h2,'Position',[425 425 900 900],'WindowStyle','Docked');
            
            for pp = 1:length(Users)
                hs(pp)=subplot(5,3,pp);
                dims = size(Users(pp).Rx.EqSubframe);
                sps = 1;
                if dims ~= [0 0]
                    iServingStation = find([Stations.NCellID] == Users(pp).NCellID);
                    [indPdsch, info] = Stations(iServingStation).getPDSCHindicies;
                    est_SubFrame = Users(pp).Rx.EqSubframe(indPdsch);
                    plot(est_SubFrame,'.')
                    title(['User: ',num2str(pp)],'Fontsize',8);
                    ylabel('Quadrature');
                    xlabel('Inphase');
                    set(hs(pp),'FontSize',8);
 
                end
                
            end
            
            
            
            


end