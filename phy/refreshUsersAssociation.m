function refreshUsersAssociation(Users, Stations, Channel, Config)
	% refreshUsersAssociation links UEs to a eNodeB
	%
	% :param Users: Array<UserEquipment> instances
	% :param Stations: Array<EvolvedNodeB> instances
	% :param Channel: Channel instance
	% :param Config: MonsterConfig instance
	
	% Loop the users to get the association based on the signal attenuation
	for iUser = 1:length(Users)
			
		% Get the ID of the eNodeB this UE has the best signal to 
		targetEnbID = Channel.getENB(Users(iUser), Stations, 'downlink');

		% Check if this UE is initialised already to a valid eNodeB. If not, don't perform HO, but simply associate
		if Users(iUser).ENodeBID == -1
			% Find an empty slot and set the context and the new eNodeBID
			iServingStation = find([Stations.NCellID] == targetEnbID);
			iFree = find([Stations(iServingStation).Users.UeId] == -1);
			iFree = iFree(1);
			ueContext = struct(...
				'UeId', Users(iUser).NCellID,...
				'CQI', Users(iUser).Rx.CQI,...
				'RSSI', Users(iUser).Rx.RSSIdBm);
				
			Stations(iServingStation).Users(iFree) = ueContext;
			Users(iUser).ENodeBID = targetEnbID;
		else
			% Call the handler for the handover that will take care of processing the change
			[Users(iUser), Stations] = handleHangover(Users(iUser), Stations, targetEnbID, Config);
		end
	end
	
	% Use the result of refreshUsersAssociation to setup the UL scheduling
	for iStation = 1:length(Stations)
		Stations(iStation).resetScheduleUL();
		Stations(iStation).setScheduleUL(Config);
	end
	for iUser = 1:length(Users)
		iServingStation = find([Stations.NCellID] == Users(iUser).ENodeBID);
		Users(iUser) = Users(iUser).setSchedulingSlots(Stations(iServingStation));
	end
end
