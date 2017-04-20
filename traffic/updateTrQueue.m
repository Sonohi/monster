function [newQueue] = updateTrQueue(src, schRound, queue)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   UPDATE TRAFFIC QUEUE is used to update the struct modelling the trx queue  %
%                                                                              %
%   Function fingerprint                                                       %
%   src        ->  traffic source as time and size of packets                  %
%   queue      ->  original UE queue with current state                        %
%   schRound   ->  scheduling round                                            %
%                                                                              %
%   newQueue	 ->  updated UE queue with new state                             %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % if the size of the queue is 0 and the simulation time is not beyond the tx
  % deadline, then update the queue
  simTime = schRound*10^-3;
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
    end;
end;
