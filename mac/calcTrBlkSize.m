function [size] = calcTrBlkSize(user, node, subFrameNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CALCULATE TRANSPORT BLOCK SIZE is used to return the TRB size for the turn %
%                                                                              %
%   Function fingerprint                                                       %
%   user        ->  the user allocated in the subframe                         %
%   node        ->  the base station serving the user                          %
%   subFrameNo  ->  subframe number                                            %
%                                                                              %
%   size	      ->  size of the transport block                                %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % get size of packet from traffic source and write it to the PDSCH struct
  % TODO
	size = node.PDSCH.CodedTrBlkSizes(mod(subFrameNo,10)+1);;

end
