%   ARQ TX defines a value class for a reordering and ARQ buffer for RLC
%		a property called state is used to handle the protocol behaviour of each individual process
%		0 means idle, 1 means in use, 2 means awaiting retransmission slot, 3 means retransmitting
% 	4 means retransmission failure

classdef ArqTx
	properties
		txId;
		rxId;
		sqn;
		bitsSize;
		tbSize;
		tbBuffer(1024, 1) = struct(...
			'tb', [], ...
			'sqn', -1, ...
			'timeStart', -1,...
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
				if isempty(rtxBuffersIndices)
					info.flag = false;
				else
					info.flag = true;
					% of all the TBs that are awaiting retransmission, pick the one that has the lowest SQN
					rtxBuffers = obj.tbBuffer(rtxBuffersIndices);
					sqnValues = [rtxBuffers.sqn];
					% find the process in the main array 
					% do not start the process as this is decided by the controller
					info.bufferIndex = find([obj.tbBuffer.sqn] == min(sqnValues));
				end
			else
				info.flag = false;
			end	
		end

		% Get SQN 
		function [obj, sqn] = getNextSqn(obj)
			sqn = obj.sqn;
			obj.sqn = obj.sqn + 1;
			if obj.sqn == 1024
				obj.sqn = 0;
			end
		end

		% Set a TB in retransmission state
		function obj = setRetransmissionState(obj, iTb)
			obj.processes(iTb).state = 3;
			obj.processes(iTb).rtxCount = obj.processes(iTb).rtxCount + 1;
		end

		% Handle the insert of a new TB
		function obj = handleTbInsert(obj, sqn, timeNow, tb)
			for ix = 1:length(obj.tbBuffer)
				if obj.tbBuffer(ix).state == 0
					obj.tbBuffer(ix).tb = tb;
					obj.tbBuffer(ix).sqn = sqn;
					obj.tbBuffer(ix).state = 1;
					obj.tbBuffer(ix).timeStart = timeNow;
					obj.bitsSize = obj.bitsSize + length(tb);
					obj.tbSize = obj.tbSize + 1;
					break;
				end
			end
		end

		% Handle the reception of an ACK
		function obj = handleAck(obj, ack, sqn, timeNow, Param)
			% find buffer index
			bufferIndices = find([obj.tbBuffer.sqn] == sqn);
			
			if ~isempty(bufferIndices)
				for iBuffer = 1: length(bufferIndices)
					iBuf = bufferIndices(iBuffer);
					if ack
						% clean
						obj = obj.pop(iBuf);
					else
						% check whether the maximum number has been exceeded
						if obj.tbBuffer(iBuf).rtxCount > Param.arq.rtxMax
							obj.tbBuffer(iBuf).state = 4;
						else
							% log rtx
							obj.tbBuffer(iBuf).rtxCount = obj.tbBuffer(iBuf).rtxCount + 1;
							obj.tbBuffer(iBuf).state = 3;
							obj.tbBuffer(iBuf).timeStart = timeNow;
						end
					end
				end
			end
			
		end

		% Method to flush TBs that have been in the buffer longer than the flush timer
		function obj = flush(obj, timeNow, Param)
			for iBuf = length(1:obj.tbBuffer)
				if timeNow - obj.tbBuffer(iTb).timeStart > Param.arq.bufferFlushTimer/1000
					obj = obj.pop(iBuf);
				end
			end
		end

		% Method to reset a transmitter
		function obj = resetTransmitter(obj)
			obj.sqn = 0;
			obj.bitsSize = 0;
			obj.tbSize = 0;
			obj.tbBuffer(1024, 1) = struct(...
				'tb', [], ...
				'sqn', -1, ...
				'timeStart', -1,...
				'rtxCount', 0,...
				'state', 0);
		end

	end

	methods (Access = private)
		% Method to execute a pop
		function obj = pop(obj, ix)
			% update stats
			obj.bitsSize = obj.bitsSize - length(obj.tbBuffer(ix).tb);
			obj.tbSize = obj.tbSize - 1;
			obj.tbBuffer(ix).tb = [];
			obj.tbBuffer(ix).sqn = -1;
			obj.tbBuffer(ix).timeStart = -1;
			obj.tbBuffer(ix).rtxCount = 0;
			obj.tbBuffer(ix).state = 0;
		end
	end
end
