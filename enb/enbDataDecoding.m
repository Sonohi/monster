function [Stations, Users] = enbDataDecoding(Stations, Users, Param, timeNow)

%   ENODEB DATA DECODING  is used to decode the received data
%
%   Function fingerprint
%   Stations		->  the eNodeB objects
%   Users		    ->  the UE objects
%   Param  			->  simulation parameters
% 	timeNow			->	current simulation time
%
%   Stations	  ->  the updated eNodeB objects
%   Users    		->  the updated UE objects

	for iStation = 1:length(Stations)
		enb = Stations(iStation);
		% First off, find all UEs that are linked to this station in this round
		% if the enb.Rx.UeData is empty, it means the eNodeB has no user in UL this round
		ueGroup = find([Users.ENodeBID] == enb.NCellID);

		enbUsers = Users(ueGroup);

		for iUser = 1:length(enb.Rx.UeData)
			if ~isempty(enb.Rx.UeData(iUser).PUCCH)
				cqi = decodeCqi(enb.Rx.UeData(iUser).PUCCH);
				ueEnodeBIX = find([enb.Users.UeId] == enb.Rx.UeData(iUser).UeId);
				if ~isempty(ueEnodeBIX)
					enb.Users(ueEnodeBIX).CQI = cqi;
				end

				% Find the transmitting HARQ process for this UE
				harqIndex = find([enb.Mac.HarqTxProcesses.rxId] == enb.Rx.UeData(iUser).UeId);
				if ~isempty(harqIndex)
					[harqPid, harqAck] = enb.Mac.HarqTxProcesses(harqIndex).decodeHarqFeedback(...
						enb.Rx.UeData(iUser).PUCCH);
					if ~isempty(harqPid)
						[enb.Mac.HarqTxProcesses(harqIndex), state, sqn] = enb.Mac.HarqTxProcesses(harqIndex).handleReply(...
							harqPid, harqAck, timeNow, Param);

						% Depending on the state, contact ARQ
						if ~isempty(sqn)
							arqIndex = find([enb.Rlc.ArqTxBuffers.rxId] == enb.Rx.UeData(iUser).UeId);

							if state == 0
								% The process has been acknowledged 
								enb.Rlc.ArqTxBuffers(arqIndex) = enb.Rlc.ArqTxBuffers(arqIndex).handleAck(1, sqn, timeNow, Param);
							elseif state == 4
								% The process has failed 
								enb.Rlc.ArqTxBuffers(arqIndex) = enb.Rlc.ArqTxBuffers(arqIndex).handleAck(0, sqn, timeNow, Param);
							else
								% Nothing to do yet, HARQ will continue trying
							end
						end
					end
				end
			end
		end
		Stations(iStation) = enb;
	end
	


end