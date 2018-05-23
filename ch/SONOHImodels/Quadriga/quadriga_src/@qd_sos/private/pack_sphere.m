function [ theta, phi, B, d_phi ] = pack_sphere( N )
%PACK_SPHERE Create equally distributed points on a unit shpere
%
%   This function equally distributes N points on a unit sphere.
%   The actual number of placed points might be smaller then N due to
%   rounding offsets.
%
% Input:
%   N       The number of points to place
%
% Output:
%   theta   Elevation angle ranging from 0 ... pi
%   phi     Azimuth angles ranging from -pi ... pi
%   B       The points in Cartesian coordinates
%
%   The output can be visualized with:
%   plot3(B(1,:),B(2,:),B(3,:),'.')
%
%
% Stephan Jaeckel
% Fraunhofer Heinrich Hertz Institute
% Wireless Communications and Networks
% Einsteinufer 37, 10587 Berlin, Germany
% e-mail: stephan.jaeckel@hhi.fraunhofer.de

a = 4*pi/N;                 % Sphere surface
d = sqrt(a);                % Distance between points

M_theta = round( pi/d );    % No. Latitudes
d_theta = pi / M_theta;     % Resolution
d_phi   = a / d_theta;

A = zeros(N+50,2);             % The output coordinates

N_count = 1;                % Number of placed points
for m = 1 : M_theta
    theta = pi * ( m-0.5 ) / M_theta;           % Current latitude
    M_phi = round( 2*pi*sin(theta)/d_phi );     % No. points on current latitude
    phi   = 2*pi*(0:M_phi-1) / M_phi;           % Longitude points
    
    N_new = numel( phi );
    A( N_count : N_count + N_new - 1 , 1 ) = theta;
    A( N_count : N_count + N_new - 1 , 2 ) = phi;
    
    N_count = N_count + N_new;
end
N_count = N_count - 1;

% Format output
theta = A(1:N_count,1)-pi/2;
phi   = angle( exp( 1j.*A(1:N_count,2) ) );

if nargout > 2
    B = zeros( 3,N_count );
    B(1,:) = cos(theta).*cos(phi);
    B(2,:) = cos(theta).*sin(phi);
    B(3,:) = sin(theta);
end

end