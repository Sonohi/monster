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
	Users(1:Param.numUsers) = struct('velocity',Param.velocity,...
		'queue',  struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0, 'scheduled', false,...
		'ueId', 0, 'position', [0 0], 'wCqi', 6);

	for iUser = 1: (Param.numUsers)
		Users(iUser).ueId	= iUser;
		Users(iUser).position = positionUser();
	end

end
