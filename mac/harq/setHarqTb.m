function Station = setHarqTb(Station, User, pid, timeNow, tb)

%   SET HARQ TB puts a newly-created TB in the buffer
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   User      	->  the UE object
% 	pid					-> 	the HARQ PID for this session
%   timeNow			->  current simulation time
%   tb					->  TB to put in queue 
%
%   Station     ->  the updated UE object

	% Find index
	iUser = find([Station.Mac.HarqTxProcesses.receiver] == User.UeId);
	% Set TB
	Station.Mac.HarqTxProcesses(iUser) = setTb(Station.Mac.HarqTxProcesses(iUser), pid, timeNow, tb);	
end
