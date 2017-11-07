function Station = setArqTb(Station, User, sqn, timeNow, tb)

%   SET ARQ TB puts a newly-created TB in the buffer
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   User      	->  the UE object
% 	sqn					-> 	the ARQ SQN for this TB
%   timeNow			->  current simulation time
%   tb					->  TB to put in queue 
%
%   Station     ->  the updated UE object

	% Find index
	iUser = find([Station.Rlc.ArqTxBuffers.rxId] == User.UeId);
	
	% Check whether the SQN has been passed in decimal or binary
	if length(sqn) > 1
		sqn = bi2de(sqn', 'left-msb');
	end
 	% Set TB
	Station.Rlc.ArqTxBuffers(iUser) = Station.Rlc.ArqTxBuffers(iUser).handleTbInsert(sqn, timeNow, tb);	
end
