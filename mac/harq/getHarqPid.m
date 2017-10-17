function pid = getHarqPid(Station, User, sqn, varargin)

%   GET HARQ PROCESS ID returns the process ID for the combination of UE, eNodeB and SQN
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   User      	->  the UE object
% 	sqn					-> 	the SQN for this session
%   varargin		->  variable number of inputs 
%
%   pid					->  the HARQ process ID

	% Check if there are any options, otherwise assume default
	outFmt = 'd';
	inFmt = 'd';
	if nargin > 0
		if varargin{1} == 'outFormat'
			outFmt = varargin{2};
		end
		if varargin{3} == 'inFormat'
			inFmt = varargin{4};
		end
	end

	% In case the SQN has been passed as binary, convert it to decimal
	if inFmt == 'b'
		sqn = bi2de(sqn')
	end

	% Let's start by searching if this is a TB that is already being transmitted and
	% is already in a HARQ process
	harqPid = -1;
	for iUser = 1:size(Station.Mac.HarqTxProc, 1)
		if Station.Mac.HarqTxProc(iUser, 1).rxId == User.UeId
			for iProc = 1:size(Station.Mac.HarqTxProc(iUser), 2)
				if sqn == decodeSqn(Station.Mac.HarqTxProc(iUser, iProc))
					harqPid = Station.Mac.HarqTxProc(iUser, iProc).processId;
					break;
				end
			end
			break;
		end 
	end

	% If the harqPid is still to -1 it means this is a new TB not in transmission
	% we need to initiate a new process
	if harqPid == -1
		for iProc = 1:size(Station.Mac.HarqTxProc(iUser), 2)
			if Station.Mac.HarqTxProc(iUser, iProc).state == 0
				harqPid = Station.Mac.HarqTxProc(iUser, iProc).processId;
				break;  
			end
		end
	end

	% Finally if the harqPid is yet still -1 it means this receiver does no longer have free processes
	% we should then terminate one and make room for this one
	if harqPid == -1

	end

	% Finally check the output format
	if outFmt ~= 'd'
		pid = de2bi(harqPid)';
		if length(pid) ~= 3
			pid = cat(1, zeros(3-length(pid), 1), pid);
		end
	else
		pid = harqPid;
	end
end
