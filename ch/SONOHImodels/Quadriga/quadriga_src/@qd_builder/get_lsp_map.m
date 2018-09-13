function map = get_lsp_map( h_builder, xc, yc, zc )
%GET_LSP_MAP Calculates the spatial map of the correlated LSPs
%
% Calling object:
%   Single object
%
%
% Input:
%   xc
%   A vector containing the map sample positions in [m] in x-direction
%
%   yc
%   A vector containing the map sample positions in [m] in y-direction
%
%   zc
%   A vector containing the map sample positions in [m] in z-direction
%
% Output:
%   map
%   An array of size [ nx, ny, nz, 8 ] containing the values of the LSPs at the sample positions.
%   The indices of the fourth dimension are:
%      * Delay spread [s]
%      * K-factor [linear]
%      * Shadow fading [linear]
%      * Azimuth angle spread of departure [rad]
%      * Azimuth angle spread of arrival [rad]
%      * Elevation angle spread of departure [rad]
%      * Elevation angle spread of arrival [rad]
%      * Cross-polarization ratio [linear]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.


if numel( h_builder ) > 1
    error('QuaDRiGa:qd_builder:ObjectArray','??? "calc_scatter_positions" is only defined for scalar objects.')
else
    h_builder = h_builder(1,1); % workaround for octave
end

if ~exist( 'yc','var' )
    yc = 0;
end

if ~exist( 'zc','var' )
    zc = 0;
end

nx = numel(xc);
ny = numel(yc);
nz = numel(zc);

ox =  ones(nx,1,'uint8');
oy =  ones(ny,1,'uint8');
oz =  ones(nz,1,'uint8');

x = reshape( single(xc) , 1, [] );
x = x( oy,:,oz );
x = x(:);

y = reshape( single(yc) , [] , 1 );
y = y( :,ox,oz );
y = y(:);

z = reshape( single(zc) , 1 , 1, []  );
z = z( oy,ox,: );
z = z(:);

map = h_builder.get_lsp_val( [x,y,z].' ).';
map = reshape( map, ny, nx, nz, [] );

end

