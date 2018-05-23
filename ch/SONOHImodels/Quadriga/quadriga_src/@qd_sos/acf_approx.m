function [ Ro, Do ] = acf_approx( h_sos )
%ACF_APPROX Generates the approximated ACF from SOS coefficients
%
%   This method calculates the approximated ACF. The distance ranges from -2 Dmax to 2 Dmax, where Dmax is the maximum
%   value in qd_sos.dist. The format of the output variable (Ro) depends on the number of dimensions.
%
%   - 1 dimension
%     Ro is a vector contining the values at the sample pints of Do.
%   - 2 dimensions 
%     Ro is a matrix containing the approximated 2D ACF
%   - 3 dimensions
%     Ro contains 3 matrices, one for the x-y plane, one for the x-z plane and one for the y-z plane.
%
% Output:
%   Ro      Approximated ACF
%   Do      Vector of sample points (in x and y direction) for the ACF in [m]
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_sos ) > 1 
   error('QuaDRiGa:qd_sos:acf_approx','acf_approx not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

% The sampling distance vector
D = h_sos.dist;
Do = [ D(1:end-1) , D(end)+D ];
Do = [ -Do(end:-1:2) , Do ];

al = h_sos.sos_amp;
fr = 2*pi*h_sos.sos_freq;

% Calculate the approximated ACF
switch h_sos.dimensions
    case 1
        Ro = al * sum(  cos( fr * Do ) , 1 );
        
    case 2
        tmp = ones(numel(Do),1,'single') * Do;
        Ro  = zeros( numel(Do) );
        for l = 1:h_sos.no_coefficients
            Ro = Ro + cos( fr(l,1)*tmp + fr(l,2)*tmp.' );
        end
        Ro = Ro * al;
        
    case 3
        tmp = ones(numel(Do),1) * Do;
        Ro  = zeros( numel(Do),numel(Do),3 );
        for l = 1:h_sos.no_coefficients
            Ro(:,:,1) = Ro(:,:,1) + cos( fr(l,1)*tmp + fr(l,2)*tmp.' );  % x-y plane
            Ro(:,:,2) = Ro(:,:,2) + cos( fr(l,1)*tmp + fr(l,3)*tmp.' );  % x-z plane
            Ro(:,:,3) = Ro(:,:,3) + cos( fr(l,2)*tmp + fr(l,3)*tmp.' );  % y-z plane
        end
        Ro = Ro * al;
        
end

Ro = double( Ro );
Do = double( Do );

end
