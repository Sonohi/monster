function [ Ri, Di ] = acf_2d( h_sos )
%ACF_2D Interpolates the ACF to a 2D version
%
%   This method calculates a 2D version of the given ACF (qd_sos.acf). The distance ranges from -2 Dmax to 2 Dmax, where
%   Dmax is the maximum value in qd_sos.dist. Values outside the specified range are set to 0. 
%
% Output:
%   Ri      2D ACF
%   Di      Vector of sample points (in x and y direction) for the 2D ACF in [m]
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_sos ) > 1 
   error('QuaDRiGa:qd_sos:acf_2d','acf_2d not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

R   = h_sos.acf;
D   = h_sos.dist;

Di = [ D(1:end-1) , D(end)+D ];
Di = [ -Di(end:-1:2) , Di ];

nDi = numel(Di);
oDi = ones(1,nDi,'uint8');

Dc  = Di( oDi,: );
Dc  = abs( Dc + 1j*Dc.' );
ind = Dc(:) <= max( D );

Ri  = zeros( nDi,nDi,'single' );
Ri(ind) = qf.interp( D, 0, R, Dc(ind) );

end
