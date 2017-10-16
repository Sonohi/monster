%   RLC BUFFER defines a value class for a reordering buffer for RLC

classdef RlcRxBuffer
	properties
		sqnExpected;
		sqnReceived;
		sqnNext;
		bitsSize;
		tbSize;
		tbBuffer;
	end;

	methods
		% Constructor
		function obj = RlcRxBuffer(Param)
			obj.sqnExpected = 1;
			obj.sqnReceived = 0;
			obj.sqnNext = 2;
			obj.bitsSize = 0;
			obj.tbSize = 0;
			obj.tbBuffer(1:Param.rlc.maxBufferSize, 1) = struct(...
				'tb', [], ...
				'sqn', 0, ...
				'timeIn', 0);
		end

		% Handle the arrival of a new TB
		function obj = handleTbReception(tb, sqn, timeNow)
			% update the buffer object
			obj.sqnReceived = sqn;
			% now check for reordering
			if obj.sqnReceived == obj.sqnExpected
				% this is the ideal case, so the TB should not be put in the buffer
				% we also have to check whether there is any TB to be removed
				for iTb = 1:length(obj.tbBuffer)
					if obj.tbBuffer(iTb).sqn <= obj.sqnExpected
						obj = pop(iTb);
					end
				end
				% update the flags
				obj.sqnExpected = obj.sqnReceived + 1;
				if obj.sqnExpected > length(obj.tbBuffer)
					obj = resetSqn();
				end
				obj.sqnNext = sqnExpected + 1;

			else if obj.sqnReceived > obj.sqnExpected
				% store this TB
				obj = push(tb, timeNow, sqn);
			else
				% in this case we received a TB that we already have.
				% This can happen due to HARQ retransmissions and we don't need it

				% log exception
			end
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
