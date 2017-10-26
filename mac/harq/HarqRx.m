%   HARQ RX defines a value class for creating anf handling a single HARQ receiver

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
		function obj = handleReply(crc, Param)
			obj.copiesReceived = obj.copiesReceived + 1;
			if crc == 0
				% All good, the TB can be decoded correctly, so we need to close off
				obj.state = 2;
			elseif obj.copiesNeeded > 1
				% else we need to check whether the number of copies received is enough
				if obj.copiesNeeded == obj.copiesReceived
					obj.state = 2;
				else
					obj.state = 3;
				end
			else
				% we are starting a retransmission session where we need more than 1 copy
				obj.copiesNeeded = estiamteCrcCopies(crc);
				obj.state = 3;
			end
		end
	end

	methods (Access = private)
		function obj = createProcesses(obj, Param, timeNow)
			% TODO check if pre-allocation can be removed or better the entire
			% function
			for iProc = 1:Param.harq.proc
				obj.processes(iProc).procId = iProc - 1;
				obj.processes(iProc).timeStart = timeNow;
			end
		end
	end
end
