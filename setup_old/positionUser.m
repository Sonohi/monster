function [pos] = positionUser(Param, id)

%   POSITION USERS is used to drop the UEs in the network
%
%   Function fingerprint
%
%   Param		-> simulation parameters
%   id			-> UEID of the user for label
%
%   pos			-> position in Manhattan grid

	pos = [randi([Param.area(1),Param.area(3)]) randi([Param.area(2),Param.area(4)]) Param.ueHeight];

    if Param.draw
			text(pos(1),pos(2)-6,strcat('UE ',num2str(id),' (',num2str(round(pos(1))),', ', ...
				num2str(round(pos(2))),')'), 'HorizontalAlignment','center','FontSize',9);

      plot(pos(1),pos(2),'^','MarkerFaceColor',[0.9 0.9 0.1],'MarkerEdgeColor', ...
				[0.1 0.1 0.1],'MarkerSize',4);
    end

end
