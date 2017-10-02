%   HARQ RX defines a value class for creating anf handling a single HARQ receiver

classdef HarqRx
	properties
		processId;
		txId;
		rxId;
		tb;
		copiesNeeded;
		state;
	end;

	methods
		% Constructor
		function obj = HarqRx(transmitter, receiver, process, tb)
			obj.rtxCount = 0;
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj.processId = process;
			obj.tb = tb;
			obj.copiesNeeded = 1:
		end

		% Handle the reception of a TB
		function obj = handleReply(crc, Param)
			if crc == 0
				% All good, the TB can be decoded correctly, so we need to close off

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


	end
end
