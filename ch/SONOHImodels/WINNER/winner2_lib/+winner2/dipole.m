function pattern = dipole(az, slant)
%DIPOLE Calculate field pattern of half wavelength dipole
% 
%   PAT = WINNER2.DIPOLE(AZ) returns the azimuth field pattern of a
%   0-degree slanted dipole at azimuth angles given in AZ (degrees). AZ
%   must be a real-valued vector. PAT is a 2 x 1 x AZLen array representing
%   vertical and horizontal polarizations, respectively, which AZLen is the
%   length of AZ.
%
%   PAT = WINNER2.DIPOLE(AZ,SLANT) returns the azimuth field pattern of a
%   slanted dipole. SLANT must be a real-valued scalar, representing the
%   counterclockwise angle (degrees) seen from the front of the dipole.
%
%   % Example: Create 45 and 90 degree slanted dipoles
% 
%   az = -180:179;  % 1 degree spacing
%   pattern45 = squeeze(winner2.dipole(az, 45));
%   pattern90 = squeeze(winner2.dipole(az, 90));
%   fh = figure; set(fh, 'Position', [100 100 1000 500]); 
%   fh.Name = 'Dipole Pattern Plots';
%   subplot(1,2,1); 
%   polarplot(az/180*pi, pattern45(1,:), 'r'); hold on;
%   polarplot(az/180*pi, pattern90(1,:), 'b'); rlim([0 1.5]);
%   legend('45 degree', '90 degree'); title('Vertical'); 
%   subplot(1,2,2); 
%   polarplot(az/180*pi, pattern45(2,:), 'r'); hold on; 
%   polarplot(az/180*pi, pattern90(2,:), 'b'); rlim([0 1.5]);
%   legend('45 degree','90 degree'); title('Horizontal'); 
% 
%   See also winner2.AntennaArray, winner2.layoutparset.

% Copyright 2016 The MathWorks, Inc.

narginchk(1, 2);

validateattributes(az, {'double'}, {'real','vector','finite'}, ...
    'dipole', 'the azimuth input');

if nargin == 2
    validateattributes(slant, {'double'}, {'real','scalar','finite'}, ...
        'dipole', 'the slant input');
    slant = -slant/180*pi; % Convert degrees to radians and flip sign
else
    slant = 0;
end

% Convert degrees to radians
az = az/180*pi;

% Transform to cartesian coordinates with the assumption of zero elevation
cart = zeros(3, length(az));
[cart(1,:), cart(2,:), cart(3,:)] = ... 
    sph2cart(az, zeros(size(az)), ones(size(az)));

% Rotation matrix in cartesian coordinates
rotMtx = [1 0          0; 
          0 cos(slant) -sin(slant); 
          0 sin(slant) cos(slant)];
 
rotCart = rotMtx * cart;

% Transform back to spherical coordinates
[~, el, ~] = cart2sph(rotCart(1,:), rotCart(2,:), rotCart(3,:));

% Coordinate system has elevation 90 deg to the zenith, while the standard
% dipole formula has zero angle in zenith. Make the conversion.
el = pi/2 - el; % [-pi/2, pi/2]

% The dipole pattern becomes singular when el = 0 or pi (cannot happen in
% this case) because sin(el) = 0
tol = 1e6*eps;
nonSingularIdx = find((abs(el) >= tol) & (abs(el-pi) >= tol));

% Ideal pattern of a slant dipole
pattern = zeros(2, 1, length(az));
pattern(:, 1, nonSingularIdx) = sqrt(1.64) *  [cos(slant); sin(slant)] * ...
    abs(cos(pi/2*cos(el(nonSingularIdx)))./sin(el(nonSingularIdx)));

% [EOF]