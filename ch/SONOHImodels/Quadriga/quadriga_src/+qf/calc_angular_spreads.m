function [ as, mean_angle ]  = calc_angular_spreads( ang, pow, wrap_angles )
%CALC_ANGULAR_SPREADS Calculates the angular spread in [rad]
%
% This function calculates the angular spread from a given set of angles. 
% 
% Input: 
%    ang   A vector of angles in [rad]. Dimensions: n_ang x n_path
%    pow   A vector of path powers in [W]. Dimensions: n_ang x n_path or 1 x n_path
% 
% Output:
%    as    The RMS angular spread for each angle vector. Dimensions: n_ang x 1
%
% QuaDRiGa Copyright (C) 2011-2016 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if ~exist('wrap_angles','var')
    wrap_angles = true;
end


N = size( ang,1 );
if size( pow,1 ) < N
    pow = pow( ones(1,N), : );
end

% Normalize powers
pt = sum( pow,2 );
pow = pow./pt( :,ones(1,size(pow,2))  );

if wrap_angles
    mean_angle = angle( sum( pow.*exp( 1j*ang ) , 2 ) ); % [rad]
else
    mean_angle = sum( pow.*ang,2 ); 
end

phi = ang - mean_angle(:,ones( 1,size(ang,2) ) );

if wrap_angles
    phi = angle( exp( 1j*phi ) );
end

as = sqrt( sum(pow.*(phi.^2),2) - sum( pow.*phi,2).^2 );

end
