function dist = interpolate_movement( h_track , si, method )
%INTERPOLATE_MOVEMENT Interpolates the movement profile to a distance vector
%
% Calling object:
%   Single object
%
% Description:
%   This function interpolates the movement profile. The distance vector at the output can then be
%   used to interpolate the channel coefficients to emulate varying speeds. See also the tutorial
%   "Applying Varying Speeds (Channel Interpolation)".
%
% Input:
%   si
%   the sampling interval in [seconds]
%
%   method
%   selects the interpolation algorithm. The default is cubic spline interpolation. Optional are:
%      * nearest - Nearest neighbor interpolation
%      * linear - Linear interpolation
%      * spline - Cubic spline interpolation
%      * pchip - Piecewise Cubic Hermite Interpolating Polynomial
%      * cubic - Cubic spline interpolation
%
%
% Output:
%   dist
%   Distance of each interpolated position from the start of the track in [m]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_track ) > 1 
   error('QuaDRiGa:qd_track:interpolate_movement','interpolate_movement not definded for object arrays.');
else
    h_track = h_track(1,1); % workaround for octave
end

if nargin == 3
    supported_types = {'nearest','linear','spline','pchip','cubic'};
    if ~( ischar(method) && any( strcmpi(method,supported_types)) )
        str = 'Interpolation method not found; supported types are: ';
        no = numel(supported_types);
        for n = 1:no
            str = [str,supported_types{n}];
            if n<no
                str = [str,', '];
            end
        end
        error(str);
    end
else
    method = 'pchip';
end

if ~( all(size(si) == [1 1]) && isnumeric(si) && isreal(si) && si >= 0 )
    error('??? Invalid sampling interval. The value must be real and > 0.')
end

if isempty(h_track.movement_profile)
    h_track.set_speed;
end

mp = h_track.movement_profile;

max_time = mp(1,end);
max_dist = mp(2,end);

t = 0 : si : max_time ;

dist = interp1(mp(1,:),mp(2,:),t,method);

dist( dist<0 ) = 0;
dist( dist>max_dist ) = max_dist;


end

