function [newQueue] = updateTrQueue(src, simTime, User)

%   UPDATE TRAFFIC QUEUE is used to update the struct modelling the trx queue
%
%   Function fingerprint
%   src        ->  traffic source as time and size of packets
%   simTime    ->  simulation time
%   User 	     ->  user object
%
%   newQueue	 ->  updated queue

	% if the size of the queue is 0 and the simulation time is not beyond the tx
	% deadline, then update the queue
	if (User.Queue.Size <= 0 && simTime >= User.Queue.Time)
		newQueue = User.Queue;
		newQueue.Size = 0;
		for (ix = 1:length(src))
			if (src(ix, 1) <= simTime)
				% increase frame size and update frame delivery deadline
				newQueue.Size = newQueue.Size + src(ix, 2);
				newQueue.Time = src(ix, 1);
			else
				% stamp the packet id in the queue and exit
				newQueue.Pkt = newQueue.Pkt + 1;
				break;
			end;
		end;
	end;
end
