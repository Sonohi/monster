function sqn = getSqn(Station, User, varargin)

%   GET SQN returns the next available SQN for the pair eNodeB & UE
%
%   Function fingerprint
% 	Station			->	the eNodeB object			
%   User      	->  the UE object
%   varargin		->  variable number of inputs 
%
%   sqn					->  the SQN assigned to this TB

	% Check if there are any options, otherwise assume default
	outFmt = 'd';
	if nargin > 0
		if varargin{1} == 'outFormat'
			outFmt = varargin{2};
		end
	end

	% Let's start by searching if this is a TB that is already being transmitted and
	% is already in the RLC buffer
	sqnTemp = -1;
	for iBuf = 1:length(Station.Rlc.ArqTxBuffer)
		if Station.Rlc.ArqTxBuffer(iBuf).rxId == User.UeId
			sqnTemp = getNextSqn(Station.Rlc.ArqTxBuffer(iBuf));
			break;
		end 
	end

	% Finally check the output format
	if outFmt ~= 'd'
		sqn = de2bi(sqnTemp)';
		if length(pid) ~= 10
			sqn = cat(1, zeros(3-length(sqn), 1), sqn);
		end
	else
		sqn = sqnTemp;
	end
end