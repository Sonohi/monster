function [pos] = positionUser(Param)

%   POSITION USERS is used to drop the UEs in the network
%
%   Function fingerprint
%
%   pos			-> position in Manhattan grid                                      

  % Not a very interesting module for now, it is structured like this for scalability

	pos = [randi([Param.area(1),Param.area(3)]) randi([Param.area(2),Param.area(4)])];

end
