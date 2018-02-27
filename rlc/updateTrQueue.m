function [Users] = updateTrQueue(Users, src, simTime)

%   UPDATE TRAFFIC QUEUE is used to update the struct modelling the trx queue
%
%   Function fingerprint
%   Users 	   ->  user object
%   src        ->  traffic source as time and size of packets
%   simTime    ->  simulation time

%
%   newQueue	 ->  updated queue
	
	for iUser = 1:length(Users)
		% first off check the id/index of the next packet to be put into the queue
		pktIx = Users(iUser).Queue.Pkt;
		if pktIx >= length(src)
			pktIx = 1;
		end
		newQueue = Users(iUser).Queue;
		for iPkt = pktIx:length(src)
			% Get all packets from the source portion that have a delivery time before the current simTime
			if src(iPkt, 1) <= simTime
				% increase frame size and update frame delivery deadline
				newQueue.Size = newQueue.Size + src(iPkt, 2);
				newQueue.Time = src(iPkt, 1);
			else
				% all packets in this delivery window have been added, save the ID of the next
				newQueue.Pkt = iPkt;
				break;
			end
		end
		% set new queue
		Users(iUser).Queue = newQueue;
	end
end
