function [Users] = createUsers (Param)

%   CREATE Users is used to generate a struct with the Users
%
%   Function fingerprint
%   Param.numUsers  ->  number of UEs
%   Param.velocity  ->  number of LTE subframes for macro eNodeBs
%
%   Users  					-> struct with all Users details

	for iUser = 1: (Param.numUsers)
		Users(iUser) = UserEquipment(Param, iUser);
		Users(iUser).Position = positionUser(Param, Users(iUser).UeId);
	end

end
