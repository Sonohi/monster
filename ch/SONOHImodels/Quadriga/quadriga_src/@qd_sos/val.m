function s = val( h_sos, coord )
%VAL Returns correlated values at given coordinates
%
% This method generates spatially correlated random variables at the given coordinates. 
%
% Input:
%   coord   Coordinates in [m] given as [3 x N] matrix. The rows correspond to the x,y and z coordinate.
%
% Output:
%   s       Vector (N elements) of spatially correlated random variables. 
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_sos ) > 1 
   error('QuaDRiGa:qd_sos:val','val not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

dims = h_sos.dimensions;
if size( coord, 1 ) > dims
    error( 'Number of requested dimensions is not supported.' );
end
coord = single( coord );
no_val = size(coord,2);

if size( coord, 1 ) < dims
    coord = [ coord; zeros( dims - size(coord,1), no_val,'single' ) ];
end

% Read local variables to increase speed
al = sqrt(h_sos.sos_amp);
ph = h_sos.sos_phase;
fr = 2*pi*h_sos.sos_freq;
L  = h_sos.no_coefficients;

if no_val < 1e4
    s = al .* sum( cos( mod( fr * coord + ph(:,ones(1,no_val,'uint8')) , 2*pi )),1);
else
    s = zeros( 1,no_val,'single' );
    for l = 1:L
        s = s + cos( mod( fr(l,:) * coord  + ph(l) , 2*pi ));
    end
    s = s .* al;
end

% Set the distribution type
switch h_sos.distribution
    case 'Normal'
        % Do nothing. The values are already Normal-distributed.
        
    case 'Uniform'
        % Transform Normal distribution to Uniform distribution
        xs = -[ 5 2 1.5 1 0.5 ]; 
        xs = [ xs,-xs(end:-1:1) ];
        zs = [ 2.86e-07, 2.28e-02, 6.69e-02, 1.59e-01, 3.09e-01]; 
        zs = [ zs, 1-zs( end:-1:1) ];
        s  = qf.interp( xs, 0, zs, s );
end

end
