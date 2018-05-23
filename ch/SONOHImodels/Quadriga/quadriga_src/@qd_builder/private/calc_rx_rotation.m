function [ aoa_c, eoa_c, deg ] = calc_rx_rotation( aoa, eoa, hdir, gdir  )
%CALC_RX_ROTATION Calculates the effective angles for the receiver
%
%   Input:
%       aoa     Azimuth of arrival angles in [rad]
%       eoa     Elevation of arrival angles in [rad]
%       hdir    Receiver rotation around y-axis (scalar)
%       gdir    Receiver rotation around z-axis (scalar)
%
%   Output:
%       aoa_c   Azimuth angles for pattern interpolation in [rad]
%       eoa_c   Elevation angles for pattern interpolation in [rad]
%       deg     The rotation angle for the polarization
%
% QuaDRiGa Copyright (C) 2011-2014 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% Save dimensions of the angles
input_size = size( aoa );

% Put all angles in a vector
aoa = aoa(:);
eoa = eoa(:);

% Store the number of values
no_angles  = numel( aoa );

if hdir == 0
    % No elevation direction is given.
    % We simplify the computations to save computing time.
    
    aoa_c = aoa - gdir;
    eoa_c = eoa;
    
    % Rotation matrix
    co = cos(gdir);
    si = sin(gdir);
    R  = [ co,-si,0 ; si,co,0 ; 0,0,1 ];
    
else
    % Full 3-D rotations.
    
    % Rotation matrix
    co = cos(-hdir);
    si = sin(-hdir);
    Ry = [ co,0,si ; 0,1,0 ; -si,0,co ];
    
    co = cos(gdir);
    si = sin(gdir);
    Rz = [ co,-si,0 ; si,co,0 ; 0,0,1 ];
    
    R  = Rz * Ry;
   
    % Transform angles to Cartesian coordinates
    C = zeros( no_angles,3 );
    C(:,1) = cos( eoa ) .* cos( aoa );
    C(:,2) = cos( eoa ) .* sin( aoa );
    C(:,3) = sin( eoa );
    
    % Apply the rotation
    C = C * R;
    
    % Transform back to spheric coordinates
    eoa_c = asin( C(:,3) );
    aoa_c = atan2( C(:,2),C(:,1) );
end

% Calculate the polarization rotations
if nargout > 2

    % Spherical basis vectors in theta direction (original angles)
    Eth_o = [ sin(eoa).*cos(aoa) , sin(eoa).*sin(aoa), -cos(eoa) ];
    
    % Spherical basis vector in phi direction (original angles)
    Eph_o = [ -sin(aoa) , cos(aoa) , zeros(no_angles,1) ];
    
    % Spherical basis vector in theta direction (new angles)
    Eth_n = [ sin(eoa_c).*cos(aoa_c) , sin(eoa_c).*sin(aoa_c), -cos(eoa_c) ];
    
    tmp = Eth_n * R';
    cos_deg = sum( Eth_o .* tmp , 2 );
    sin_deg = sum( Eph_o .* tmp , 2 );
    
    deg = atan2( sin_deg, cos_deg );
    deg = reshape( deg, input_size );
end

% Reshape output to match input
eoa_c = reshape( eoa_c, input_size );
aoa_c = reshape( aoa_c, input_size );

end
