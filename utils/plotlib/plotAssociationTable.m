function plotAssociationTable(Users, Cells, Config, Plot)
	% plotAssociationTable plots the associations during simulation runtime
	% 
	% :param Users: Array<UserEquipment> instances
	% :param Cells: Array;EvolvedNodeB: instances
	% :param Config: MonsterConfig instance
	% :param Plot: Struct plot axes
	%

	LayoutFigure = Plot.LayoutFigure;
	%clear table if present
	tableAssociation = findobj(LayoutFigure, 'Tag', 'table');
	if ~isempty(tableAssociation)
		delete(tableAssociation);
	end

	%New table
	tableAssociation = cell(Config.Ue.number ,3);
	tIndex= 1;
	for iCell = 1:length(Cells)
		Cell = Cells(iCell);
		% Find all scheduled users in DL
		
		scheduledusers = [Cell.ScheduleDL.UeId];
		scheduledusers = unique(scheduledusers(scheduledusers ~= -1));
		
		for user = 1:length(scheduledusers)
			rxObj = Users(find([Users.NCellID] == scheduledusers(user)));
			tableAssociation{tIndex,1} = strcat('UE ', num2str(rxObj.NCellID));
			tableAssociation{tIndex,2} = 'Scheduled at';
			tableAssociation{tIndex,3} = strcat('BS ', num2str(Cell.NCellID));
			tIndex = tIndex+1;
		end
		
		% Plot all associated users (available in Users)
		associatedusers = [Cell.Users.UeId];
		associatedusers = associatedusers(associatedusers ~= -1);
		if ~isempty(associatedusers)
			associatedusers = associatedusers(~ismember(associatedusers,scheduledusers));
			for user = 1:length(associatedusers)
				rxObj = Users(find([Users.NCellID] == associatedusers(user)));
				tableAssociation{tIndex,1} = strcat('UE ', num2str(rxObj.NCellID));
				tableAssociation{tIndex,2} = 'Associated to';
				tableAssociation{tIndex,3} = strcat('BS ', num2str(Cell.NCellID));
				tIndex = tIndex+1;
			end
		end
	end
	uit = uitable(LayoutFigure);
	uit.Tag = 'table';
	uit.Data = tableAssociation;
	uit.Position = [700 100 300 300];

end