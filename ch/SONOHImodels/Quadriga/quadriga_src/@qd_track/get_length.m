function [ len, dist ] = get_length( h_track )
%GET_LENGTH Calculates the length of the track in [m]
%
% Calling object:
%   Object array
%
% Output:
%   len
%   Length of a track in [m]
%
%   dist
%   Distance of each position (snapshot) from the start of the track in [m]
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
    
    % Do for each element in array
    sic     = size( h_track );
    len     = zeros( sic );
    dist    = cell( sic );
    
    for n=1:numel(h_track)
        [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
        [ len(i1,i2,i3,i4), dist{i1,i2,i3,i4} ] = get_length( h_track(i1,i2,i3,i4) );
    end
    
else   
            
    p = h_track(1,1).positions;
    for n = 1 : 3
        p(n,:) = p(n,:) - p(n,1);
    end
        
    if isempty( h_track(1,1).Plength ) || nargout == 2
        dist = zeros(1,h_track(1,1).no_snapshots);
        for n=2:h_track(1,1).no_snapshots
            dist(n) = sqrt(sum(( p(:,n) - p(:,n-1) ).^2));
        end
        dist = cumsum(dist);
        len = dist(end);
        h_track(1,1).Plength = len;
    else
        len = h_track(1,1).Plength;
    end
    
end

