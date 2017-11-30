function [ h1, h2 ] = plotReGrids(Users)
h1 = figure('Name','Rx grid');
set(h1,'Position',[425 425 900 900],'WindowStyle','Docked','Visible','on');

for pp = 1:length(Users)
	hs(pp)=subplot(5,3,pp);
	dims = size(Users(pp).Rx.Subframe);
	if dims ~= [0 0]
		surf(20*log10(abs(Users(pp).Rx.Subframe)));
		title(['User: ',num2str(pp)],'Fontsize',8);
		ylabel('Subcarrier');
		xlabel('Symbol');
		zlabel('absolute value (dB)');
		axis([1 dims(2) 1 dims(1) -40 10]);
		set(hs(pp),'FontSize',8);
	else
		
	end
end


h2 = figure('Name','Eq grid');
set(h2,'Position',[425 425 900 900],'WindowStyle','Docked','Visible','on');

for pp = 1:length(Users)
	hs(pp)=subplot(5,3,pp);
	dims = size(Users(pp).Rx.Subframe);
	if dims ~= [0 0]
		surf(20*log10(abs(Users(pp).Rx.Subframe)));
		title(['User: ',num2str(pp)],'Fontsize',8);
		ylabel('Subcarrier');
		xlabel('Symbol');
		zlabel('absolute value (dB)');
		axis([1 dims(2) 1 dims(1) -40 10]);
		set(hs(pp),'FontSize',8);
	else
		
	end
end

end

