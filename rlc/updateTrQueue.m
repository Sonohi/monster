function [Users] = updateTrQueue(src, schRound, Users)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UPDATE TRAFFIC QUEUE is used to update the struct modelling the trx queue  %
%                                                                              %
%   Function fingerprint                                                       %
%   src        ->  traffic source as time and size of packets                  %
%   schRound   ->  scheduling round                                            %
%   Users      ->  users connected to a eNodeB					                       %
%                                                                              %
%   Users			 ->  updated UE structs								                           %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % if the size of the queue is 0 and the simulation time is not beyond the tx
  % deadline, then update the queue
	simTime = schRound*10^-3;
	for (iUser = 1:length(Users))
		if (Users(iUser).ueId ~= 0)
			queue = Users(iUser).queue;
  		if (queue.size <= 0 && simTime >= queue.time)
    		newQueue = queue;
    		newQueue.size = 0;
    		for (ix = 1:length(src))
      		if (src(ix, 1) <= simTime)
		        % increase frame size and update frame delivery deadline
		        newQueue.size = newQueue.size + src(ix, 2);
		        newQueue.time = src(ix, 1);
		      else
		        % stamp the packet id in the queue and exit
		        newQueue.pkt = newQueue.pkt + 1;
		        break;
      		end;
					% Update struct
					Users(iUser).queue = newQueue;
    		end;
			end;
		end;
	end;
