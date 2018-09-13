function save( h_sos, filename )
%SAVE Saves the coefficients to a mat-file
%
%  Sinusoid coefficients can be stored in a mat-file. In this way, it is possible to precompute the sinusoid
%  coefficients and save some significant time when initializing the method. It is possible to adjust the decorrelation
%  distance of a precomputed function without needing to perform the calculations again.
%
% Input:
%   filename 	Path or filename to the coefficient file. 
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_sos ) > 1 
   error('QuaDRiGa:qd_sos:save','save not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

if exist( 'filename', 'var' )
   h_sos.name = filename;
end

fr   = h_sos.sos_freq;
acf  = h_sos.acf;
dist = h_sos.dist;

save( h_sos.name,'fr','acf','dist' );

end
