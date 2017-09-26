%   HARQ TX defines a value class for creating anf handling a single HARQ transmitter

classdef HarqTx
	properties
		processId;
		txId;
		rxId;
		rtxCount;
		rv;
		tb;
		tstart;
		state;
	end;

	methods
		% Constructor
		function obj = HarqTx(transmitter, receiver, process, tb, tnow)
			obj.rtxCount = 0;
			obj.rv = 0;
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj.processId = process;
			obj.tb = tb;
			obj.tStart = tnow;
			obj.state = 0;
		end

		% set TB
		function obj = set.tb(obj, tb)
			obj.tb =  tb;
		end

		% Handle the reception of a ACK/NACk
		function obj = handleReply(ack, Param)
			if ack.msg == 1
				% clean
				obj.rtxCount = 0;
				obj.rv = 0;
				obj.txId = -1;
				obj.rxId = -1;
				obj.tb = [];
				obj.tStart = -1;
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
					obj.tStart = tnow;
			end
		end

		% Handle the expiration of the retransmission timer
		function obj = handleTimeout(tnow)
			% log failure
			obj.rtxCount = obj.rtxCount + 1;
			obj.rv = Param.harq.rv(obj.rtxCount);
			obj.state = 2;
			obj.tStart = tnow;
		end
	end
end
