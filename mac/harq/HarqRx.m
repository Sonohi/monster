%   HARQ RX defines a value class for the receiver end of the HARQ protocol.
%		a property called state is used to model the protocol behaviour of the receiver process
% 	it assumes value 0 for a default state that corresponds to an unused or successful process
% 	and value 1 for a process awaiting retransmission copies


classdef HarqRx
	properties
		bitsSize;
		tbSize;
		processes(8,1) = struct(...
			'copiesNeeded',1,...
			'copiesReceived',0,...
			'tb', [],...
			'state', 0, ...
			'timeStart', -1,...
			'procId', -1);
	end

	methods
		% Constructor
		function obj = HarqRx(Param, timeNow)
			obj.bitsSize = 0;
			obj.tbSize = 0;
			obj = createProcesses(obj, Param, timeNow);
		end

		% Handle the reception of a TB
		function [obj, state] = handleTbReception(obj, iProc, tb, crc, Param, timeNow)
			obj.processes(iProc).copiesReceived = obj.processes(iProc).copiesReceived + 1;
			if crc == 0
				% All good, the TB can be decoded correctly so no need to proceed further
				% Reset process
				obj = obj.resetProcess(iProc);
			elseif obj.processes(iProc).copiesNeeded > 1
				% in this case it means we already started earlier for retransmissions 
				% for this process and we need to check whether the number of copies is sufficient
				if obj.processes(iProc).copiesNeeded == obj.processes(iProc).copiesReceived
					obj = obj.resetProcess(iProc);
				else
					obj.processes(iProc).state = 1;
				end
			else
				% in this last case, we are starting a retransmission session 
				% so we need to know how many copies will be needed 
				obj.processes(iProc).copiesNeeded = estimateCrcCopies(crc);
				obj.processes(iProc).state = 1;
				obj.processes(iProc).tb = tb;
				obj.processes(iProc).timeStart = timeNow;
			end
			state = obj.processes(iProc).state;
		end

		% Decodes a HARQ PID from the header of the TB
		function [pid, pidIndex] = decodeHarqPid(obj, tb)
			harqBits = tb(1:3, 1);
			pid = bi2de(harqBits', 'left-msb');
			pidIndex = find([obj.processes.procId] == pid);
		end
	end

	methods (Access = private)
		function obj = createProcesses(obj, Param, timeNow)
			% TODO check if pre-allocation can be removed or better the entire
			% function
			for iProc = 1:Param.harq.proc
				obj.processes(iProc).procId = iProc - 1;
			end
		end

		%Utility to reset a process
		function obj = resetProcess(obj, iProc)
			obj.processes(iProc).state = 0;
			obj.processes(iProc).copiesReceived = 0;
			obj.processes(iProc).timeStart = -1;
		end
	
	end
end
