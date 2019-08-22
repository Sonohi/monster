function [User, Cells] = handleHangover(User,Cells,targetEnbID, Config)
	% handleHangover performs the steps of the handover procedure
	%
	% :User: UserEquipment
	% :Cells: Array<EvolvedNodeB> instances
	% :Channel: Integer NCellId of the target eNodeB after the handover
	% :Config: MonsterConfig instance
	%
	% :User: UserEquipment instance with association updated to targetEnb
	% :Cells: Array<EvolvedNodeB> instances with updated associations
	%

	% We handle the change only if the target eNodeB is not the current one
	if targetEnbID ~= User.ENodeBID
		% Check the current state of the Hangover process in the UE
		% 0 means the UE is not currently in a HO process and can initiate one
		% 1 means the UE has already initiated a HO process
		
		if User.Hangover.HoState == 0
			% in this case, we can initiate the HO procedure. This is the only case when we actually use the target eNodeB
			User.Hangover.HoState = 1;
			User.Hangover.TargetEnb = targetEnbID;
			User.Hangover.HoStart = Config.Runtime.currentTime;
			User.Hangover.HoComplete = Config.Runtime.currentTime + Config.Handover.x2Timer;
		elseif User.Hangover.HoState == 1 && User.Hangover.HoComplete <= Config.Runtime.currentTime
			% perform hangover
			% Get indices
			iServingCell = find([Cells.NCellID] == User.ENodeBID);
			iTargetCell = find([Cells.NCellID] == targetEnbID);
			
			% move UE context
			iUser = find([Cells(iServingCell).Users.UeId] == User.NCellID);
			ueContext = Cells(iServingCell).Users(iUser);
			% Clean the serving eNodeB
			Cells(iServingCell).Users(iUser).UeId = -1;
			Cells(iServingCell).Users(iUser).CQI = -1;
			Cells(iServingCell).Users(iUser).RSSI = [];
			
			% Find an empty slot and set the context and the new eNodeBID
			iFree = find([Cells(iTargetCell).Users.UeId] == -1);
			iFree = iFree(1);
			Cells(iTargetCell).Users(iFree) = ueContext;
			User.ENodeBID = targetEnbID;
			
			% Clean hangover struct
			User.Hangover.HoState = 0;
			User.Hangover.TargetEnb = -1;
			User.Hangover.HoStart = -1;
			User.Hangover.HoComplete = -1;
			if Config.Harq.active
				% Now move the HARQ and ARQ processes (if any)
				iServingRlc = find([Cells(iServingCell).Rlc.ArqTxBuffers.rxId] == User.NCellID);
				if iServingRlc
					% Clean the transmitter in the serving
					arqTxObject = Cells(iServingCell).Rlc.ArqTxBuffers(iServingRlc);
					% Edit the TtxId field to the target eNodeB
					arqTxObject.txId = targetEnbID;
					Cells(iServingCell).Rlc.ArqTxBuffers(iServingRlc) = ...
						Cells(iServingCell).Rlc.ArqTxBuffers(iServingRlc).resetTransmitter();
					
					% find the user slot in the target, update the SQN and set the object
					iTargetRlc = find([Cells(iTargetCell).Rlc.ArqTxBuffers.rxId] == User.NCellID);
					Cells(iTargetCell).Rlc.ArqTxBuffers(iTargetRlc) = arqTxObject;
				end
				
				% Do similarly for MAC
				iServingMac = find([Cells(iServingCell).Mac.HarqTxProcesses.rxId] == User.NCellID);
				if iServingMac
					% Clean the transmitter in the serving
					harqTxObject = Cells(iServingCell).Mac.HarqTxProcesses(iServingMac);
					% Edit the TtxId field to the target eNodeB
					harqTxObject.txId = targetEnbID;
					% Reset the object in the serving Cell
					Cells(iServingCell).Mac.HarqTxProcesses(iServingMac) = ...
						Cells(iServingCell).Mac.HarqTxProcesses(iServingMac).resetTransmitter();
					
					% find the user slot in the target and set the object
					iTargetMac = find([Cells(iTargetCell).Mac.HarqTxProcesses.rxId] == User.NCellID);
					Cells(iTargetCell).Mac.HarqTxProcesses(iTargetMac) = harqTxObject;
				end
			end
		else
			%in all the other cases we either do not need to perform HO at all or the timer has not expired yet
			
		end
		
	end
end
