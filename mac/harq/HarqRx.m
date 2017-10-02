%   HARQ RX defines a value class for creating anf handling a single HARQ receiver

classdef HarqRx
	properties
		processId;
		txId;
		rxId;
		tb;
		copiesNeeded;
		copiesReceived;
		state;
	end;

	methods
		% Constructor
		function obj = HarqRx(transmitter, receiver, process, tb)
			obj.txId = transmitter;
			obj.rxId = receiver;
			obj.processId = process;
			obj.tb = tb;
			obj.state = 1;
			obj.copiesNeeded = 1:
			obj.copiesReceived = 0:
		end

		% Handle the reception of a TB
		function obj = handleReply(crc, Param)
			obj.copiesReceived = obj.copiesReceived + 1;
			if crc == 0
				% All good, the TB can be decoded correctly, so we need to close off
				obj.state = 2;
			else if obj.copiesNeeded > 1
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
end
