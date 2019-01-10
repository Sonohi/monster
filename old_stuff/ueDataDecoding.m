function [Stations, Users] = ueDataDecoding(Stations, Users, Param, timeNow)

%   UE DATA DECODING  is used to decode the TB data
%
%   Function fingerprint
%   Stations		->  the eNodeB objects
%   Users		    ->  the UE objects
%   Param  			->  simulation parameters
% 	timeNow			->	current simulation time
%
%   Stations	  ->  the updated eNodeB objects
%   Users    		->  the updated UE objects

	% Loop users to check if they received something and then assign that to the 
	% respective receiver process
	for iUser = 1:length(Users)
		if ~isempty(Users(iUser).Rx.TransportBlock) && Param.rtxOn
			[harqPid, iProc] = Users(iUser).Mac.HarqRxProcesses.decodeHarqPid(...
				Users(iUser).Rx.TransportBlock);
			harqPidBits = de2bi(harqPid, 3, 'left-msb')';
			if length(harqPidBits) ~= 3
				harqPidBits = cat(1, zeros(3-length(harqPidBits), 1), harqPidBits);
			end
			if ~isempty(iProc)
				% Handle HARQ TB reception
				[Users(iUser).Mac.HarqRxProcesses, state] = ...
					Users(iUser).Mac.HarqRxProcesses.handleTbReception(iProc,...
					Users(iUser).Rx.TransportBlock, Users(iUser).Rx.Crc, Param, timeNow);
					
				% Depending on the state the process is, contact ARQ
				if state == 0
					sqn = Users(iUser).Rlc.ArqRxBuffer.decodeSqn(Users(iUser).Rx.TransportBlock);
					if ~isempty(sqn)
						Users(iUser).Rlc.ArqRxBuffer = Users(iUser).Rlc.ArqRxBuffer.handleTbReception(...
							sqn, Users(iUser).Rx.TransportBlock, timeNow);
					end	
					% Set ACK and PID information for this UE to report back to the serving eNodeB 
					Users(iUser).Mac.HarqReport.pid = harqPidBits;
					Users(iUser).Mac.HarqReport.ack = 1;
				else
					% in this case, the process has entered or remained in the state where it needs TB copies
					% we should not then contact the ARQ, but just send back a NACK
					Users(iUser).Mac.HarqReport.pid = harqPidBits;
					Users(iUser).Mac.HarqReport.ack = 0;
				end	
			end
		end
	end


end