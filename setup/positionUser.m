function [pos] = positionUser()

%   POSITION USERS is used to drop the UEs in the network
%
%   Function fingerprint
%
%   pos			-> position in Manhattan grid                                      

  % Not a very interesting module for now, it is structured like this for scalability

	pos = [randi([1,10]) randi([1,10])];

end
