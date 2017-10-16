%   RLC BUFFER defines a value class for a reordering buffer for RLC

classdef RlcTxBuffer
	properties
		sqn;
		bitsSize;
		tbSize;
		tbBuffer;
	end;

	methods
		% Constructor
		function obj = RlcTxBuffer(Param)
			obj.sqn = 0;
			obj.bitsSize = 0;
			obj.tbSize = 0;
			obj.tbBuffer(1:Param.rlc.maxBufferSize, 1) = struct(...
				'tb', [], ...
				'sqn', 0, ...
				'timeIn', 0);
		end

		% Handle the insert of a new TB
		function obj = handleTbInsert(tb, timeNow)
			obj.sqn = obj.sqn + 1;
			obj = push(tb, timeNow, obj.sqn);
		end

		% Handle the insert of an ACK
		function obj = handleAck(ack, sqn)
			
		end

		% Method to flush TBs that have been in the buffer longer than the flush timer
		function obj = flush(timeNow, Param)
			for iTb = length(1:obj.tbBuffer)
				if timeNow - obj.tbBuffer(iTb).timeIn > Param.rlc.bufferFlushTimer/1000
					obj = pop(iTb);
				end
			end
		end

	end

	methods (Access = private)
		% Method to execute a pop
		function obj = pop(ix)
			% update stats
			obj.bitsSize = obj.bitsSize - length(obj.tbBuffer(ix).tb);
			obj.tbSize = obj.tbSize - 1;
			obj.tbBuffer(ix).tb = [];
			obj.tbBuffer(ix).sqn = 0;
			obj.tbBuffer(ix).timeIn = 0;
		end

		% Method to execute a push
		function obj = push(tb, timeNow, sqn)
			% pushing occurs on the first unused slot
			for ix = 1:length(obj.tbBuffer)
				if ~isempty(obj.tbBuffer(ix).tb)
					obj.tbBuffer(ix).tb = tb;
					obj.tbBuffer(ix).sqn = sqn;
					obj.tbBuffer(ix).timeIn = timeNow;
					obj.bitsSize = obj.bitsSize + length(tb);
					obj.tbSize = obj.tbSize + 1;
				end
			end
		end

		% Method to reset the SQN
		function obj = resetSqn()
			%TODO
		end
	end
end
