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
		if ~isempty(Users(iUser).Rx.TransportBlock)
			[harqPid, iProc] = decodeHarqPid(Users(iUser).Mac.HarqRxProcesses, Users(iUser).Rx.TransportBlock);
			if ~isempty(iProc)
				% Handle HARQ TB reception
				[Users(iUser).Mac.HarqRxProcesses, state] = handleTbReception(iProc, Users(iUser).Mac.HarqRxProcesses,...
					Users(iUser).Rx.TransportBlock, Users(iUser).Rx.Crc, Param, timeNow);
				% Depending on the state the process is, contact ARQ
				if state == 0
					sqn = decodeSqn(Users(iUser).Rlc.ArqRxBuffer, Users(iUser).Rx.TransportBlock);
					if ~isempty(sqn)
						Users(iUser).Rlc.ArqRxBuffer = handleTbReception(sqn, Users(iUser).Rx.TransportBlock, timeNow);
					end	
					% Send back an ACK for this TB
					% TODO ACK transmission 

				else
					% in this case, the process has entered or remained in the state where it needs TB copies
					% we should not then contact the ARQ, but just send back a NACK
					% TODO NACK transmission 	
					
				end	
			end
		end
	end


end