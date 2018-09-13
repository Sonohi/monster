function h_sos = load( filename )
%LOAD Loads coefficients from mat file
%
% Sinusoid coefficients can be stored in a mat-file by calling qd\_sos.save. This (static) method loads them again. In
% this way, it is possible to precompute the sinusoid coefficients and save some significant time when initializing the
% method. It is possible to adjust the decorrelation distance of a precomputed function without needing to perform the
% calculations again.
%
% Input:
%   filename 	Path or filename to the coefficient file. 
%
% Output:
%   h_sos   A qd_sos object.
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

load(filename);

h_sos                   = qd_sos([]);
h_sos.name              = filename;
h_sos.Pdist_decorr      = single( dist( find( acf <= exp(-1) ,1 ) ) );
h_sos.dist              = single( dist );
h_sos.acf               = single( acf );
h_sos.sos_freq          = single( fr );
h_sos.sos_amp           = single( 1 / size(fr,1) );

h_sos.init;

end

