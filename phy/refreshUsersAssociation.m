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
	StationsC.Tx.Waveform = StationsC.Tx.Frame;
	StationsC.Tx.WaveformInfo = StationsC.Tx.FrameInfo;
	StationsC.Tx.Grid = StationsC.Tx.FrameGrid;
	
	% Now loop the users to get the association based on the signal attenuation
	for iUser = 1:length(Users)
		% Get the ID of the eNodeB this UE has the best signal to 
		targetEnbID = Channel.getAssociation(StationsC,Users(iUser));

		% Call the handler for the handover that will take care of processing the change
		[Users(iUser), StationsC] = handleHangover(Users(iUser), StationsC, targetEnbID, Param, timeNow);

		% Now that the assignment is done, write also on the side of the station
		% TODO replace with matrix operation
		for iStation = 1:length(Stations)
			if Stations(iStation).NCellID == Users(iUser).ENodeBID
				for ix = 1:Param.numUsers
					if Stations(iStation).Users(ix).UeId == -1
						Stations(iStation).Users(ix).UeId = Users(iUser).NCellID;
						Stations(iStation).Users(ix).CQI = Users(iUser).Rx.CQI;
						Stations(iStation).Users(ix).RSSI = Users(iUser).Rx.RSSIdBm;
						break;
					end
				end
				break;
			end
		end
	end

	% Use the result of refreshUsersAssociation to setup the UL scheduling
	for iStation = 1:length(Stations)
		Stations(iStation) = Stations(iStation).setScheduleUL(Param);
	end
	for iUser = 1:length(Users)
		iServingStation = [Stations.NCellID] == Users(iUser).ENodeBID;
		Users(iUser) = Users(iUser).setSchedulingSlots(Stations(iServingStation));
	end
end
