function rotate_pattern( h_qd_arrayant, deg, rotaxis, i_element, usage )
%ROTATE_PATTERN Rotates antenna patterns
%
% Calling object:
%   Single object
%
% Description:
%   Pattern rotation provides the option to assemble array antennas out of single elements. By
%   setting the 'element_position' property of an array object, elements can be placed at different
%   coordinates. In order to freely design arbitrary array configurations, however, elements often
%   need to be rotated (e.g. to assemble a +/- 45° crosspolarized array out of single dipoles).
%   This functionality is provided here.
%
% Input:
%   deg
%   The rotation angle in [degrees] ranging from -180° to 180°
%
%   rotaxis
%   The rotation axis specified by the character 'x','y', or 'z'.
%
%   i_element
%   The element indices for which the rotation is done. If no element index is given, the rotation
%   is done for all elements in the array.
%
%   usage
%   The optional parameter 'usage' can limit the rotation procedure either  to the pattern or
%   polarization. Possible values are:
%      * 0: Rotate both (pattern+polarization) - default
%      * 1: Rotate only pattern
%      * 2: Rotate only polarization
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_qd_arrayant ) > 1 
   error('QuaDRiGa:qd_arrayant:calc_gain','calc_gain not definded for object arrays.');
else
    h_qd_arrayant = h_qd_arrayant(1,1); % workaround for octave
end

% Parse input arguments
if exist('deg','var')
    if ~( all(size(deg) == [1 1]) && isnumeric(deg) ...
            && isreal(deg) )
        error('??? "deg" must be integer and real')
    end
else
    deg = 0;
end

if exist('rotaxis','var')
    if ~( ischar(rotaxis) && ...
            (strcmp(rotaxis,'x') || strcmp(rotaxis,'y')  || strcmp(rotaxis,'z')) )
        error('??? "rotaxis" can only be x,y or z.')
    end
else
    rotaxis = 'y';
end

if exist('i_element','var') && ~isempty( i_element )
    if ~( size(i_element,1) == 1 && isnumeric(i_element) ...
            &&  all( mod(i_element,1)==0 ) && min(i_element) > 0 && max(i_element)<=h_qd_arrayant(1,1).no_elements )
        error('??? "i_element" must be integer > 0 and can not exceed the number of elements')
    end
else
    i_element = 1:h_qd_arrayant(1,1).no_elements;
end

if exist('usage','var')
    if ~( all(size(usage) == [1 1]) && isnumeric(usage) ...
            && any(usage == [0,1,2]) )
        error('??? "usage" must be 0,1 or 2')
    end
else
    usage = 0;
end

% Get the angles.
phi   = h_qd_arrayant(1,1).azimuth_grid;
theta = h_qd_arrayant(1,1).elevation_grid';
no_az = h_qd_arrayant(1,1).no_az;
no_el = h_qd_arrayant(1,1).no_el;

% Rotation vectors are given in degree, but calculations are done in rad.
deg = deg/180*pi;

% Rotations are only allowed axis-wise where for each axis, another
% rotation matrix is given.
ct = cos( deg );
st = sin( deg );
switch rotaxis
    case 'x'
        rot = [ 1 0 0 ; 0 ct -st ; 0 st ct ];
    case 'y'
        rot = [ ct 0 st ; 0 1 0 ; -st 0 ct ];
    case 'z'
        rot = [ ct -st 0 ; st ct 0 ; 0 0 1 ];
end

% Calculate the transformation matrices for transforming the pattern from
% spherical coordinates to Cartesian coordinates.
B(1,:,:) = cos(theta)*cos(phi);             % Matrix-vector notation is faster
B(2,:,:) = cos(theta)*sin(phi);             % ... then meshgrid and sph2cart
B(3,:,:) = sin(theta)*ones(1,no_az);

A = rot.' * reshape(B, 3, []);
A = reshape( A.' , no_el,no_az,3 );

% Fix numeric bounds
A(A>1)  = 1;
A(A<-1) = -1;

% Calculate new angles
[phi_new, theta_new] = cart2sph( A(:,:,1), A(:,:,2), A(:,:,3) ) ;

% Angles might become complex, if the values in A are out of bound due
% to numeric offsets.
phi_new   = real( phi_new );
theta_new = real( theta_new );

% When the angles map to the poles of the pattern (i.e. theta = +/- 90
% degree), the pattern is not defined anymore. Here, we correct this by 
% using a small offset angle.
err_limit = 1e-5;

s = theta_new < -pi/2 + err_limit;
theta_new(s)  = -pi/2 + err_limit;

s = theta_new > pi/2 - err_limit;
theta_new(s)  = pi/2 - err_limit;

% Calculate the transformation for the polarization
if usage == 0 || usage == 2
    % Spherical basis vector in theta direction (original angles)
    Eth_o(1,:,:) = sin(theta)  * cos(phi);
    Eth_o(2,:,:) = sin(theta)  * sin(phi);
    Eth_o(3,:,:) = -cos(theta) * ones(1,no_az);
    Eth_o = reshape( Eth_o, 3, []);
    
    % Spherical basis vector in phi direction (original angles)
    Eph_o(1,:,:) = ones(no_el,1) * -sin(phi);
    Eph_o(2,:,:) = ones(no_el,1) * cos(phi);
    Eph_o(3,:,:) = zeros( no_el , no_az );
    Eph_o = reshape( Eph_o, 3, []);
    
    % Spherical basis vector in theta direction (new angles)
    Eth_n(1,:,:) = sin(theta_new) .* cos(phi_new);
    Eth_n(2,:,:) = sin(theta_new) .* sin(phi_new);
    Eth_n(3,:,:) = -cos(theta_new);
    Eth_n = reshape( Eth_n, 3, []);
    
    tmp = rot * Eth_n;
    cos_psi = sum( Eth_o .* tmp , 1 );
    sin_psi = sum( Eph_o .* tmp , 1 );
    
    cos_psi = reshape( cos_psi, no_el,no_az );
    sin_psi = reshape( sin_psi, no_el,no_az );
end

for n = 1:numel(i_element)
    
    % When we have the angles from the projection, we interpolate the
    % 3D field patterns to get the new (rotated) patterns. This is done
    % by the interpolation routine.
    
    % Interpolate the pattern
    if usage == 0 || usage == 1
        [ V,H ] = h_qd_arrayant(1,1).interpolate( phi_new, theta_new , i_element(n) );
    else
        V = h_qd_arrayant(1,1).Fa(:,:,i_element(n));
        H = h_qd_arrayant(1,1).Fb(:,:,i_element(n));
    end
    
    % Update the element position
    h_qd_arrayant(1,1).element_position(:,i_element(n)) = rot*h_qd_arrayant(1,1).element_position(:,i_element(n));
    
    % Transformation of the polarization
    if usage == 0 || usage == 2
        
        patV = cos_psi.*V - sin_psi.*H;
        patH = sin_psi.*V + cos_psi.*H;
        
        h_qd_arrayant(1,1).Fa(:,:,i_element(n)) = patV;
        h_qd_arrayant(1,1).Fb(:,:,i_element(n)) = patH;
        
    else % mode 1 - Rotate patterns only, but not the polarization
        
        h_qd_arrayant(1,1).Fa(:,:,i_element(n)) = V;
        h_qd_arrayant(1,1).Fb(:,:,i_element(n)) = H;
        
    end
end

end
