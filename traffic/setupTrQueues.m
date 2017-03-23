function [queues] = setupTrQueues (users)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   SETUP TRAFFIC QUEUES is used to initialise a struct for the queues         %
%                                                                              %
%   Function fingerprint                                                       %
%   users   ->  struct of the UEs                                              %
%                                                                              %
%   queues  ->  queues structSizes                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % Initialise structe
  queues(length(users)).qsz = 0;
  for (i = 1:length(users))
    queues(i).UEID = users(i).UEID;
    queues(i).qsz = 0;
  end
