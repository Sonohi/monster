function init( h_sos )
%INIT Initializes the random phases
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel(h_sos) > 1
    
    sic = size( h_sos );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            init( h_sos(i1,i2,i3,i4) );
            prc( qf.eqo( h_sos(i1,i2,i3,i4), h_track ) ) = true;
        end
    end
    
else
    h_sos(1,1).sos_phase = single( 2*pi*(rand(h_sos(1,1).no_coefficients,1)-0.5) );
end

end
