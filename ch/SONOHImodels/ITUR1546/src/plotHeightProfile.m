function sg3db = plotHeightProfile(sg3db)
% this function plots the height profile as defined in the structure sg3db
%
% Author: Ivica Stevanovic, Federal Office of Communications, Switzerland
% Revision History:
% Date            Revision
% 24NOV2014       Modified to fit non-GUI implementation
% 06SEP2013       Introduced corrections in order to read different
%                 versions of .csv file (netherlands data, RCRCU databank and kholod data)
% 22JUL2013       Initial version (IS)

x=sg3db.x;
h_gamsl=sg3db.h_gamsl;

%% plot the profile
ax=axes;
sg3db.h=plot(ax,x,h_gamsl,'LineWidth',2,'Color','k');
set(ax,'XLim',[min(x) max(x)]);
hTx=sg3db.hTx;
hRx=sg3db.hRx;
%area(ax,x,h_gamsl)


title(ax,['Tx: ' sg3db.TxSiteName ', Rx: ' sg3db.RxSiteName ', ' sg3db.TxCountry]);
set(ax,'XGrid','on','YGrid','on');
xlabel(ax,'distance [km]');
ylabel(ax,'height [m]');

% % plot radio meteorogical code 4-land, 3-coast, 1-sea
% if(~isempty(sg3db.radio_met_code))
%     x2=sg3db.x(2:end);
%     x1=sg3db.x(1:end-1);
%     x=(x2+x1)/2;
%     x=[0 x];
%     x(end)=x2(end);
%     c=sg3db.radio_met_code;
%     y=[0 1];
%     [X Y]=meshgrid(x,y);
%     C=meshgrid(c,y);
%     h=pcolor(ax,X,Y,C);
%     set(h,'EdgeColor','none')
%     caxis(ax,[1 4]);
%     set(ax,'ytick',[], 'yticklabel',{});
% end
% % plot clutter code - there are four different possibilities.


