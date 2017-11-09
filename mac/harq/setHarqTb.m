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
	iUser = find([Station.Mac.HarqTxProcesses.rxId] == User.NCellID);
	
	% Check whether the pid has bene passed in decimal or binary
	if length(pid) > 1
		pid = bi2de(pid', 'left-msb');
	end
 	% Set TB
	Station.Mac.HarqTxProcesses(iUser) = Station.Mac.HarqTxProcesses(iUser).handleTbInsert(pid, timeNow, tb);	
end
