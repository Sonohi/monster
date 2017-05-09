function [Users] = createUsers (Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE Users is used to generate a struct with the Users                   %
%                                                                              %
%   Function fingerprint                                                       %
%   Param.numUsers  ->  number of UEs                                          %
%   Param.velocity  ->  number of LTE subframes for macro eNodeBs              %
%                                                                              %
%   Users  					-> struct with all Users details                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Not a very interesting module for now, it is structured like this for scalability
	% Initialise struct
	Users(1:Param.numUsers) = struct('position', positionUser(), 'velocity',Param.velocity,...
		'queue',  struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0)

	for iUser = 1: (Param.numUsers)
		Users(iUser).ueId			= i;
	end

end
