function [User, Stations] = handleHangover(User,Stations,targetEnbID, Param, timeNow)

%   HANDLE HANGOVER is used to handle hangovers
%
%   Function fingerprint
%   User  				->  the UE object
%   Stations			->  array of eNodeBs
%		targetEnbID		->	the ID of the (possibly) eNodeB target
% 	timeNow				->	the current simulation time
%
%   User  				->  updated UE object
%   Stations			->  updated eNodeBs array

	% We handle the change only if the target eNodeB is not the current one
	if targetEnbID ~= User.ENodeBID
		% Check the current state of the Hangover process in the UE
		% 0 means the UE is not currently in a HO process and can initiate one
		% 1 means the UE has already initiated a HO process

		if User.Hangover.HoState == 0
			% in this case, we can initiate the HO procedure. This is the only case when we actually use the target eNodeB
			User.Hangover.HoState = 1;
			User.Hangover.TargetEnb = targetEnbID;
			User.Hangover.HoStart = timeNow;
			User.Hangover.HoComplete = timeNow + Param.handoverTimer;
		elseif User.Hangover.HoState == 1 && User.Hangover.HoComplete <= timeNow
			% perform hangover
			% Get indices
			iServingStation = find([Stations.NCellID] == User.ENodeBID);
			iTargetStation = find([Stations.NCellID] == targetEnbID);

			% move UE context
			iUser = find([Stations(iServingStation).Users.UeId] == User.NCellID);
			ueContext = Stations(iServingStation).Users(iUser);
			% Clean the serving eNodeB
			Stations(iServingStation).Users(iUser).UeId = -1;
			Stations(iServingStation).Users(iUser).CQI = -1;
			Stations(iServingStation).Users(iUser).RSSI = -1;

			% Find an empty slot and set the context and the new eNodeBID
			iFree = find([Stations(iServingStation).Users.UeId] == -1);
			iFree = iFree(1);
			Stations(iTargetStation).Users(iFree) = ueContext;
			User.ENodeBID = targetEnbID;

			% Now move the HARQ and ARQ processes (if any)
			iServingRlc = find([Stations(iServingStation).Rlc.ArqTxBuffers.rxId] == User.NCellID);
			if iServingRlc
				% Clean the transmitter in the serving
				arqTxObject = Stations(iServingStation).Rlc.ArqTxBuffers(iServingRlc);
				% Edit the TtxId field to the target eNodeB
				arqTxObject.txId = targetEnbID;
				Stations(iServingStation).Rlc.ArqTxBuffers(iServingRlc) = ...
					Stations(iServingStation).Rlc.ArqTxBuffers(iServingRlc).resetTransmitter();

				% find the user slot in the target and set the object
				iTargetRlc = find([Stations(iTargetStation).Rlc.ArqTxBuffers.rxId] == User.NCellID);
				Stations(iTargetStation).Rlc.ArqTxBuffers(iTargetRlc) = arqTxObject;
			end

			% Do similarly for MAC
			iServingMac = find([Stations(iServingStation).Mac.HarqTxProcesses.rxId] == User.NCellID);
			if iServingMac
				% Clean the transmitter in the serving
				harqTxObject = Stations(iServingStation).Mac.HarqTxProcesses(iServingMac);
				% Edit the TtxId field to the target eNodeB
				harqTxObject.txId = targetEnbID;
				% Reset the object in the serving station
				Stations(iServingStation).Mac.HarqTxProcesses(iServingMac) = ...
					Stations(iServingStation).Mac.HarqTxProcesses(iServingMac).resetTransmitter();

				% find the user slot in the target and set the object
				iTargetMac = find([Stations(iTargetStation).Mac.HarqTxProcesses.rxId] == User.NCellID);
				Stations(iTargetStation).Mac.HarqTxProcesses(iTargetMac) = harqTxObject;
			end

		else
			%in all the other cases we either do not need to perform HO at all or the timer has not expired yet 
			
		end

	end
end
