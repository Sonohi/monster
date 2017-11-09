function [Users, Stations] = refreshUsersAssociation(Users,Stations,Channel,Param)

%   REFRESH USERS ASSOCIATION links UEs to a eNodeB
%
%   Function fingerprint
%   Users   		->  array of UEs
%   Stations		->  array of eNodeBs
%
%   nodeUsers ->  Users indexes associated with node

	% reset stations
	for (iStation = 1:length(Stations))
		Stations(iStation) = resetUsers(Stations(iStation), Param);
	end

	% Create copy of stations that is used computing associating, e.g.
	% no users associated but the one in the loop. No UeId should be saved
	% to this one.
	StationsC = Stations;

	% Now check what round we are in. A waveform is needed to simulate the association
	% so to cover also the first case with no previously transmitted waveform

	for i = 1:length(StationsC)
		if (sum([StationsC(i).Tx.Waveform]) == 0)
			[StationsC(i).Tx.Waveform, StationsC(i).Tx.WaveformInfo, StationsC(i).Tx.ReGrid] = ...
				generateDummyFrame(StationsC(i));
		end
	end

	d0=1; % m
	for (iUser = 1:length(Users))
		% get UE position
		uePos = Users(iUser).Position;
		minLossDb = 200;

		stationCellID = Channel.getAssociation(StationsC,Users(iUser));

		Users(iUser).ENodeBID = stationCellID;

		% Now that the assignement is done, write also on the side of the station
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
