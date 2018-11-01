function [Users] = createUsers (Param)

%   CREATE Users is used to generate a struct with the Users
%
%   Function fingerprint
%   Param.numUsers  ->  number of UEs
%
%   Users  					-> struct with all Users details

	for iUser = 1: (Param.numUsers)
		Users(iUser) = UserEquipment(Param, iUser);
	end

	if Param.draw
		legend('Location','northeastoutside')
	else

end
