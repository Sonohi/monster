function refreshUsersAssociation(Users, Cells, Channel, Config, timeNow)
	% refreshUsersAssociation links UEs to a eNodeB
	%
	% :param Users: Array<UserEquipment> instances
	% :param Cells: Array<EvolvedNodeB> instances
	% :param Channel: Channel instance
	% :param Config: MonsterConfig instance
	% :param timeNow: Int current simulation time
	
	% Loop the users to get the association based on the signal attenuation
	for iUser = 1:length(Users)
			
		% Get the ID of the eNodeB this UE has the best signal to 
		targetEnbID = Channel.getENB(Users(iUser), Cells, 'downlink');

		% Check if this UE is initialised already to a valid eNodeB. If not, don't perform HO, but simply associate
		if Users(iUser).ENodeBID == -1
			% Find an empty slot and set the context and the new eNodeBID
			iServingCell = find([Cells.NCellID] == targetEnbID);
			iFree = find([Cells(iServingCell).Users.UeId] == -1);
			iFree = iFree(1);
			ueContext = struct(...
				'UeId', Users(iUser).NCellID,...
				'CQI', Users(iUser).Rx.CQI.wideBand,...
				'RSSI', Users(iUser).Rx.RSSIdBm);
				
			%Cells(iServingCell).Users(iFree) = ueContext;
			Cells(iServingCell).associateUser(Users(iUser));
			Users(iUser).ENodeBID = targetEnbID;
		else
			% Call the handler for the handover that will take care of processing the change
			[Users(iUser), Cells] = handleHangover(Users(iUser), Cells, targetEnbID, Config, timeNow);
		end
	end
	

end
