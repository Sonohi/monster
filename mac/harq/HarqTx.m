%   HARQ TX defines a value class for creating anf handling a single HARQ transmitter

classdef HarqTx
	properties
		txId;
		rxId;
		processes;
		rtxCount;
		rv;
		tb;
		timeStart;
		state;
	end;

	methods
		% Constructor
		function obj = HarqTx(Param, transmitter, receiver)
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj = createProcesses();
			obj.bitsSize = 0;
			obj.
			obj.rtxCount = 0;
			obj.rv = 0;
			
			obj.processId = process;
			obj.tb = tb;
			obj.timeStart = timeNow;
			obj.state = 0;
		end

		% set TB
		function obj = set.tb(obj, tb)
			obj.tb =  tb;
		end

		% Handle the reception of a ACK/NACk
		function obj = handleReply(obj, ack, timeNow, Param)
			if ack.msg == 1
				% clean
				obj.rtxCount = 0;
				obj.rv = 0;
				obj.txId = -1;
				obj.rxId = -1;
				obj.tb = [];
				obj.timeStart = -1;
				obj.state = 0;
			else
				% check whether the maximum number has been exceeded
				if obj.rtxCount > Param.harq.rtxMax
					% log failure (and notify RLC?)
					obj.state = 3;
				else
					% log rtx
					obj.rtxCount = obj.rtxCount + 1;
					obj.rv = Param.harq.rv(obj.rtxCount);
					obj.state = 1;
					obj.timeStart = timeNow;
				end
			end
		end

		% Handle the expiration of the retransmission timer
		function obj = handleTimeout(obj, timeNow)
			% log failure
			obj.rtxCount = obj.rtxCount + 1;
			obj.rv = Param.harq.rv(obj.rtxCount);
			obj.state = 2;
			obj.tStart = timeNow;
		end

		% Decode the SQN from a TB in storage and returns it
		function sqn = decodeSqn(obj, varargin)
			% Check if there are any options, otherwise assume default
			outFmt = 'd'
			if nargin > 0
				if varargin{1} == 'format'
					outFmt = varargin{2};
				end
			end

			sqnBits(1:10, 1) = obj.tb(1:10,1); 
			if outFmt == 'b'
				sqn = sqnBits;
			else
				sqn = bi2de(sqnBits');
			end
		end
	end

	methods (Access = private)
		function obj = createProcesses(obj)
			
		end
	end
end
