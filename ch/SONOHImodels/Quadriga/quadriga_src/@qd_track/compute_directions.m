function compute_directions( h_track )
%COMPUTE_DIRECTIONS Calculates ground and height orientations from positions
%
% Calling object:
%   Object array
%
% Description:
%   This function calculates the orientations of the terminal based on the positions. If we assume
%   that the receive array antenna is fixed on a car and the car moves along the track, then the
%   antenna turns with the car when the car is changing direction. This needs to be accounted for
%   when generating the channel coefficients. This function calculates the orientation based on the
%   positions and stored the output in the ground_direction and height_direction field of the track
%   object.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel(h_track) > 1
    
    sic = size( h_track );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            compute_directions( h_track(i1,i2,i3,i4) );
            prc( qf.eqo( h_track(i1,i2,i3,i4), h_track ) ) = true;
        end
    end
    
else
    if h_track(1,1).no_snapshots<2
        h_track(1,1).Pground_direction = 0;
        h_track(1,1).Pheight_direction = 0;
        
    else
        P = h_track(1,1).Ppositions(:,2:end) - h_track(1,1).Ppositions(:,1:end-1);
        [a, e] = cart2sph(P(1, :), P(2, :), P(3, :));
        
        n = h_track(1,1).no_snapshots;
        if h_track(1,1).closed
            a(n) = a(1);
            e(n) = e(1);
        else
            a(n) = a(n-1);
            e(n) = e(n-1);
        end
        
        h_track(1,1).ground_direction = a;
        h_track(1,1).height_direction = e;
    end
end
end