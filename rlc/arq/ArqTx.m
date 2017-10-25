%   ARQ TX defines a value class for a reordering and ARQ buffer for RLC
%		a property called state is used to handle the protocol behaviour of each individual process
%		0 means idle, 1 means in use, 2 means awaiting retransmission slot, 3 means retransmitting
% 	4 means retransmission failure

classdef ArqTx
	properties
		transmitter;
		receiver;
		sqn;
		bitsSize;
		tbSize;
		tbBuffer(1024, 1) = struct(...
			'tb', [], ...
			'sqn', 0, ...
			'timeStart', 0,...
			'rtxCount', 0,...
			'state', 0);
	end

	methods
		% Constructor
		function obj = ArqTx(Param, transmitter, receiver, timeNow)
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj.sqn = 0;
			obj.bitsSize = 0;
			obj.tbSize = 0;
		end

		% Utility to check whether any retransmission should be done
		function info = getRetransmissionState(obj)
			% check if this receiver has anything at all in the buffer
			if obj.bitsSize > 0 
				rtxBuffersIndices = find([obj.tbBuffer.state] == 2);
				if length(rtxBuffersIndices) == 0
					info.flag = false;
				else
					info.flag = true;
					% of all the TBs that are awaiting retransmission, pick the one that has the lowest SQN
					rtxBuffers = obj.tbBuffer(rtxBuffersIndices);
					sqnValues = [rtxBuffers.sqn];
					minSqn = min(sqnValues);
					% find the process in the main array 
					% do not start the process as this is decided by the controller
					info.bufferIndex = find([obj.tbBuffer.sqn] == min(sqnValues));
				end
			else
				info.flag = false;
			end	
		end

		% Handle the insert of a new TB
		function obj = handleTbInsert(tb, timeNow)
			obj.sqn = obj.sqn + 1;
			for ix = 1:length(obj.tbBuffer)
				if ~isempty(obj.tbBuffer(ix).tb)
					obj.tbBuffer(ix).tb = tb;
					obj.tbBuffer(ix).sqn = sqn;
					obj.tbBuffer(ix).timeStart = timeNow;
					obj.bitsSize = obj.bitsSize + length(tb);
					obj.tbSize = obj.tbSize + 1;
				end
			end;
		end

		% Handle the insert of an ACK
		function obj = handleAck(ack, sqn)
			
		end

		% Method to flush TBs that have been in the buffer longer than the flush timer
		function obj = flush(timeNow, Param)
			for iTb = length(1:obj.tbBuffer)
				if timeNow - obj.tbBuffer(iTb).timeStart > Param.rlc.bufferFlushTimer/1000
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
			obj.tbBuffer(ix).timeStart = 0;
		end

		% Method to reset the SQN
		function obj = resetSqn()
			%TODO
		end
	end
end
