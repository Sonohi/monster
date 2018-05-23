function set_grid( h_qd_arrayant , azimuth_grid , elevation_grid )
%SET_GRID Sets a new grid for azimuth and elevation and interpolates the pattern
%
% Calling object:
%   Single object
%
% Description:
%   This function replaces the properties 'azimuth_grid' and 'elevation_grid' of the antenna object
%   with the given values and interpolates the antenna patterns to the new grid.
%
% Input:
%   azimuth_grid
%   Azimuth angles in [rad] were samples of the field patterns are provided The field patterns are
%   given in spherical coordinates. This variable provides the azimuth sampling angles in radians
%   ranging from -π to π.
%
%   elevation_grid
%   Elevation angles in [rad] were samples of the field patterns are provided The field patterns
%   are given in spherical coordinates. This variable provides the elevation sampling angles in
%   radians ranging from -π/2 (downwards) to π/2 (upwards).
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if nargin < 3
    error('QuaDRiGa:qd_arrayant:wrongNumberOfInputs',...
        'Wrong number of input arguments.');
end

if isempty( azimuth_grid ) || isempty( elevation_grid )
    error('QuaDRiGa:qd_arrayant:wrongInputValue',...
        'Input arguments can not be empty.');
end

if ~( any( size(elevation_grid) == 1 ) && isnumeric(elevation_grid) && isreal(elevation_grid) &&...
        max(elevation_grid)<=pi/2 && min(elevation_grid)>=-pi/2 )
    error('QuaDRiGa:qd_arrayant:wrongInputValue','??? "elevation_grid" must be a vector containing values between -pi/2 and pi/2')
end

if ~( any( size(azimuth_grid) == 1 ) && isnumeric(azimuth_grid) && isreal(azimuth_grid) &&...
        max(azimuth_grid)<=pi && min(azimuth_grid)>=-pi )
    error('QuaDRiGa:qd_arrayant:wrongInputValue','??? "azimuth_grid" must be a vector containing values between -pi and pi')
end

if numel(h_qd_arrayant) > 1
    
    sic = size( h_qd_arrayant );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            set_grid( h_qd_arrayant(i1,i2,i3,i4), azimuth_grid, elevation_grid );
            prc( qf.eqo( h_qd_arrayant(i1,i2,i3,i4), h_qd_arrayant ) ) = true;
        end
    end
    
else
    
    el = repmat( elevation_grid' , 1 , numel(azimuth_grid) );
    az = repmat( azimuth_grid , numel(elevation_grid) , 1 );
    
    iEl = elevation_grid <= max(h_qd_arrayant(1,1).elevation_grid) & ...
        elevation_grid >= min(h_qd_arrayant(1,1).elevation_grid);
    
    iAz = azimuth_grid <= max(h_qd_arrayant(1,1).azimuth_grid) & ...
        azimuth_grid >= min(h_qd_arrayant(1,1).azimuth_grid);
    
    [V,H] = h_qd_arrayant(1,1).interpolate( az(iEl,iAz) , el(iEl,iAz) , 1:h_qd_arrayant(1,1).no_elements  );
   
    h_qd_arrayant(1,1).elevation_grid = elevation_grid(iEl);
    h_qd_arrayant(1,1).azimuth_grid = azimuth_grid(iAz);
    
    h_qd_arrayant(1,1).Fa = V;
    h_qd_arrayant(1,1).Fb = H;
end

end
