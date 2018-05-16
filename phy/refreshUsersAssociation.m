function [Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param, timeNow)

%   REFRESH USERS ASSOCIATION links UEs to a eNodeB
%
%   Function fingerprint
%   Users   		->  array of UEs
%   Stations		->  array of eNodeBs
%		Param				->	the simulation parameters 
% 	timeNow			->	the current simulation time
%
%   Users   		->  updated array of UEs
%   Stations		->  updated array of eNodeBs

	% Create a local copy
	StationsC = Stations;
	%Set the stored dummy frame as current waveform
	for iStation = 1:length(Stations)
		StationsC(iStation).Tx.Waveform = StationsC(iStation).Tx.Frame;
		StationsC(iStation).Tx.WaveformInfo = StationsC(iStation).Tx.FrameInfo;
		StationsC(iStation).Tx.ReGrid = StationsC(iStation).Tx.FrameGrid;
		StationsC(iStation).Users(1:Param.numUsers) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
	end
	
	
	% Now loop the users to get the association based on the signal attenuation
	for iUser = 1:length(Users)
		% Get the ID of the eNodeB this UE has the best signal to 
		targetEnbID = Channel.getAssociation(StationsC,Users(iUser));

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
			[Users(iUser), Stations] = handleHangover(Users(iUser), Stations, targetEnbID, Param, timeNow);
		end
	end
	
	

	% Use the result of refreshUsersAssociation to setup the UL scheduling
	for iStation = 1:length(Stations)
		Stations(iStation) = Stations(iStation).resetScheduleUL();
		Stations(iStation) = Stations(iStation).setScheduleUL(Param);
	end
	for iUser = 1:length(Users)
		iServingStation = find([Stations.NCellID] == Users(iUser).ENodeBID);
		Users(iUser) = Users(iUser).setSchedulingSlots(Stations(iServingStation));
	end
end
