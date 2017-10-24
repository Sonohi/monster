%   HARQ TX defines a value class for creating anf handling a single HARQ transmitter
%		a property called state is used to handle the protocol behaviour of each individual process
%		0 means idle, 1 means in use, 2 means retransmitting, 3 means failure

classdef HarqTx
	properties
		txId;
		rxId;
		bitsSize = 0;
		tbSize = 0;
		processes(8,1) = struct(...
			'rtxCount',0,...
			'rv', 0, ....
			'tb', [],...
			'state', 0, ...
			'timeStart', -1,...
			'procId', -1);
	end

	methods
		% Constructor
		function obj = HarqTx(Param, transmitter, receiver, timeNow)
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj.bitsSize = 0;
			obj.tbSize = 0;
			obj = createProcesses(obj, Param, timeNow);
		end

		% Returns a HARQ PID based on a SQN if the process exists
		% otherwise it terminates one
		function [obj, pid, newTb] = findProcess(obj, sqn)
			newTb = false;
			procs = obj.processes;
			pid = -1;
			for iProc = 1:length(procs)
				if sqn == decodeSqn(procs(iProc).tb)
					pid = procs(iProc).procId;
				else 
					if iProc == length(procs)
					% if there is no match for the SQN and we are at the last process slot
					% then we need to start a new process 
					newTb = true;
					[obj, pid] = startNewProcess(obj, sqn);
					end
				end
			end
		end

		% set tb
		function obj = setTb(obj, pid, timeNow, tb)
			iProc = find([obj.processes.procId] == pid);
			obj.processes(iProc).tb = tb;
			obj.processes(iProc).timeStart = timeNow;
		end

		% Handle the reception of a ACK/NACk
		function obj = handleReply(obj, ack, procId, timeNow, Param)
			% find index
			iProc = [obj.processes.procId] == procId;
			if ack.msg == 1
				% clean
				obj.processes(iProc).rtxCount = 0;
				obj.processes(iProc).rv = 0;
				obj.processes(iProc).tb = [];
				obj.processes(iProc).timeStart = -1;
				obj.processes(iProc).state = 0;
			else
				% check whether the maximum number has been exceeded
				if obj.processes(iProc).rtxCount > Param.harq.rtxMax
					% log failure (and notify RLC?)
					obj.processes(iProc).state = 3;
				else
					% log rtx
					obj.processes(iProc).rtxCount = obj.processes(iProc).rtxCount + 1;
					obj.processes(iProc).rv = Param.harq.rv(obj.rtxCount);
					obj.processes(iProc).state = 2;
					obj.processes(iProc).timeStart = timeNow;
				end
			end
		end

		% Handle the expiration of the retransmission timer
		function obj = handleTimeout(obj, timeNow)
			% find index
			iProc = [obj.processes.procId] == procId;
			% log failure
			obj.processes(iProc).rtxCount = obj.processes(iProc).rtxCount + 1;
			obj.processes(iProc).rv = Param.harq.rv(obj.processes(iProc).rtxCount);
			obj.processes(iProc).state = 2;
			obj.processes(iProc).timeStart = timeNow;
		end

	end

	methods (Access = private)
		function obj = createProcesses(obj, Param, timeNow)
			% TODO check if pre-allocation can be removed or better the entire
			% function
			for iProc = 1:Param.harq.proc
				obj.processes(iProc).procId = iProc;
				obj.processes(iProc).timeStart = timeNow;
			end
		end

		% Decode the SQN from a TB in storage and returns it
		function sqn = decodeSqn(tb, varargin)
			% Check if there are any options, otherwise assume default
			outFmt = 'd'
			if nargin > 0
				if varargin{1} == 'format'
					outFmt = varargin{2};
				end
			end

			if length(tb) > 0
				sqnBits(1:10, 1) = tb(1:10,1); 
				if outFmt == 'b'
					sqn = sqnBits;
				else
					sqn = bi2de(sqnBits');
				end
			else
				sqn = -1;
			end	
		end

		% Utility to start a new process 
		function [obj, pid] = startNewProcess(obj, sqn)
			% First of all, find whether there is any process that is not used currently
			idleProcsIndices = find([obj.processes.state] == 0);
			if length(idleProcsIndices ~= 0)
				% A free process is available
				iProc = idleProcsIndices(1);
				obj.processes(iProc).state = 1;
				pid = obj.processes(iProc).procId;
			else
				% Stop a process and use that slot for the new TB
				% Get the process that has been in the buffer the longest and delete that
				timeStartValues = [obj.processes.timeStart];
				[~, pid] = min(timeStartValues);
				obj.processes(pid).state = 1;
			end
		end

	end
end
