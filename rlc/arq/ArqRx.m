%   ARQ RX defines a value class for a reordering buffer for ARQ receiver

classdef ArqRx
	properties
		sqnExpected;
		sqnReceived;
		sqnNext;
		bitsSize;
		tbSize;
		tbBuffer(1024, 1) = struct(...
			'tb', [], ...
			'sqn', -1, ...
			'timeStart', -1);
	end

	methods
		% Constructor
		function obj = ArqRx(Param, timeNow)
			obj.sqnExpected = 0;
			obj.sqnReceived = 0;
			obj.sqnNext = 1;
			obj.bitsSize = 0;
			obj.tbSize = 0;
		end

		% Handle the arrival of a new TB
		function obj = handleTbReception(obj, sqn, tb, timeNow)
			% update the buffer object
			obj.sqnReceived = sqn;
			% now check for reordering
			if obj.sqnReceived == obj.sqnExpected
				% this is the ideal case, so the TB should not be put in the buffer
				% we also have to check whether there is any TB to be removed
				for iTb = 1:length(obj.tbBuffer)
					if obj.tbBuffer(iTb).sqn <= obj.sqnExpected && obj.tbBuffer(iTb).sqn ~= -1
						obj = pop(obj, iTb);
					end
				end
				% update the flags
				obj.sqnExpected = obj.sqnReceived + 1;
				if obj.sqnExpected > length(obj.tbBuffer)
					obj.sqnExpected = 0;
				end
				obj.sqnNext = obj.sqnExpected + 1;

			elseif obj.sqnReceived > obj.sqnExpected
				% store this TB
				obj = push(obj, tb, timeNow, sqn);
			else
				% in this case we received a TB that we already have.
				% This can happen due to HARQ retransmissions and we don't need it
				sonohilog('ARQ received duplicate TB', 'NFO');
			end
		end

		% Method to decode the SQN in a TB
		function sqn = decodeSqn(obj, tb)
			sqnBits = tb(4:13);
			sqn = bi2de(sqnBits', 'left-msb');
		end

		% Method to flush TBs that have been in the buffer longer than the flush timer
		function obj = flush(timeNow, Param)
			for iTb = length(1:obj.tbBuffer)
				if timeNow - obj.tbBuffer(iTb).timeStart > Param.arq.bufferFlushTimer/1000
					obj = pop(iTb);
				end
			end
		end

	end

	methods (Access = private)
		% Method to execute a pop
		function obj = pop(obj, ix)
			% update stats and check that we don't go below 0
			szTemp = obj.bitsSize - length(obj.tbBuffer(ix).tb);
			if szTemp > 0
				obj.bitsSize = szTemp;
			else
				obj.bitsSize = 0;
			end
			szTemp = obj.tbSize - 1;
			if szTemp > 0
				obj.tbSize = szTemp;
			else
				obj.tbSize = 0;
			end
			obj.tbBuffer(ix).tb = [];
			obj.tbBuffer(ix).sqn = -1;
			obj.tbBuffer(ix).timeStart = -1;
		end

		% Method to execute a push
		function obj = push(obj, tb, timeNow, sqn)
			% pushing occurs on the first unused slot
			for ix = 1:length(obj.tbBuffer)
				if ~isempty(obj.tbBuffer(ix).tb)
					obj.tbBuffer(ix).tb = tb;
					obj.tbBuffer(ix).sqn = sqn;
					obj.tbBuffer(ix).timeStart = timeNow;
					obj.bitsSize = obj.bitsSize + length(tb);
					obj.tbSize = obj.tbSize + 1;
				end
			end
		end
	end
end
