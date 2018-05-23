function set_speed( h_track , speed , no_chk )
%SET_SPEED Sets a constant speed in [m/s] for the entire track. 
%
% Calling object:
%   Object array
%
% Description:
%   This function fills the 'track.movement_profile' field with a constant speed value. This helps
%   to reduce computational overhead since it is possible to reduce the computation time by
%   interpolating the channel coefficients.
%
% Input:
%   speed
%   The terminal speed in [m/s]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if nargin < 3 || ~logical( no_chk )
    if exist( 'speed','var' )
        if ~isempty( speed )
            if ~( all(size(speed) == [1 1]) && isnumeric(speed) && isreal(speed) && speed > 0 )
                error('??? Invalid sampling interval. The value must be real and > 0.')
            end
        end
    else
        speed = 1;
    end
end

if numel(h_track) > 1
    
    sic = size( h_track );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            set_speed( h_track(i1,i2,i3,i4), speed, false );
            prc( qf.eqo( h_track(i1,i2,i3,i4), h_track ) ) = true;
        end
    end
    
else
    if isempty( speed )
        h_track(1,1).movement_profile = [];
    else
        len = h_track(1,1).get_length;
        h_track(1,1).movement_profile = [ 0 , len/speed ; 0 len ];
    end
end

end

