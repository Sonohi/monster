function plotLinks(Users, Cells, LayoutPlot, chtype)

	% If the links have been added before, delete them
	hScheduled = findobj(LayoutPlot,'Tag','ScheduledLinks');
	if ~isempty(hScheduled)
		delete(hScheduled)
	end

	hAssociated = findobj(LayoutPlot,'Tag','AssociatedLinks');

	if ~isempty(hAssociated)
		delete(hAssociated)
	end

	for iCell = 1:length(Cells)
		Cell = Cells(iCell);
		txPos = Cell.Position;
		% Plot all scheduled users
		switch chtype
			case 'downlink'
				scheduledusers = [Cell.ScheduleDL.UeId];
				scheduledusers = unique(scheduledusers(scheduledusers ~= -1));
			case 'uplink'
				scheduledusers = [Cell.ScheduleUL.UeId];
				scheduledusers = unique(scheduledusers(scheduledusers ~= -1));
		end
		for user = 1:length(scheduledusers)
			rxObj = Users(find([Users.NCellID] == scheduledusers(user)));
			rxPos = rxObj.Position;
			hScheduled = plot(LayoutPlot, [txPos(1), rxPos(1)], [txPos(2), rxPos(2)],'k:', 'linewidth',3, 'DisplayName', strcat('BS ', num2str(Cell.NCellID),'-> UE ', num2str(rxObj.NCellID),' (scheduled)'), 'Tag','ScheduledLinks');
		end

		% Plot all associated users (available in Users)
		associatedusers = [Cell.Users.UeId];
		associatedusers = associatedusers(associatedusers ~= -1);
		if ~isempty(associatedusers)
			associatedusers = associatedusers(~ismember(associatedusers,scheduledusers));
			for user = 1:length(associatedusers)
				rxObj = Users(find([Users.NCellID] == associatedusers(user)));
				rxPos = rxObj.Position;
				hAssociated = plot(LayoutPlot, [txPos(1), rxPos(1)], [txPos(2), rxPos(2)],'k--',  'DisplayName', strcat('BS ', num2str(Cell.NCellID),'-> UE ', num2str(rxObj.NCellID)),'Tag', 'AssociatedLinks');
			end
		end
	end
	drawnow
end