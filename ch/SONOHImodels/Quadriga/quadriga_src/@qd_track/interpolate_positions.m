function interpolate_positions( h_track, samples_per_meter )
%INTERPOLATE_POSITIONS Interpolates positions along the track
%
% Calling object:
%   Object array
%
% Description:
%   This function interpolates the positions along the track such that it matches the samples per
%   meter specifies in the simulation parameters. The channel model operates on a position-based
%   sample grid. That means that the 'builder' generates one CIR for each position on the track. In
%   practise, however, a time continuous evolution of the CIR is often needed. This can be
%   interpolated from the position-based grid, provided that the spatial sample theorem is not
%   violated (i.e. the channel needs to be sampled at least twice per half wave length). In order
%   to do that, enough sample points are needed along the track. This function calculates the
%   missing sample points and places them equally spaced along the track. This corresponds to a
%   constant speed when evaluating the output CIR. The required value for 'samples_per_meter' can
%   be obtained from the 'qd_simulation_parameters' object.
%
% Input:
%   samples_per_meter
%   the samples per meter (e.g. from 'qd_simulation_parameters.samples_per_meter')
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
    sic = size( h_track );
    for n=1:numel(h_track)
        [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
        interpolate_positions( h_track(i1,i2,i3,i4), samples_per_meter );
    end
    
else
    if h_track(1,1).no_snapshots == 1
        error('Minimum number of snapshots for interpolation must be 2');
    end
    
    closed = h_track(1,1).closed;
    sr = 1/samples_per_meter;
    
    % Calculate distance vector
    dist = zeros( 1,h_track(1,1).no_snapshots );
    for i_snap = 2 : h_track(1,1).no_snapshots
        dist(i_snap) = sum( ( h_track(1,1).positions(:,i_snap-1) -...
            h_track(1,1).positions(:,i_snap) ).^2 )^0.5;
    end
    dist = cumsum(dist);
    
    % Calculate interpolation target
    max_dist = max(dist);
    no_snap  = ceil( max_dist/sr );
    
    sr = max_dist / no_snap;
    dist_int = 0 : sr : (max_dist - 0.5*sr) ;
    dist_int(end+1) = max_dist;
    
    pos_int = zeros( 3,size(dist_int,2) );
    for n = 1:3
        pos_int(n,:) = pchip(dist, h_track(1,1).positions(n,:) ,dist_int);
    end
    
    segment_index_int = h_track(1,1).segment_index;
    for i_seg = 1:h_track(1,1).no_segments
        [ ~, segment_index_int(i_seg) ] = min( abs( dist_int -...
            dist( h_track(1,1).segment_index(i_seg) ) ) );
    end
    
    % Interpolate parameters, if provided
    if ~isempty( h_track(1,1).par )
        par = h_track(1,1).par;
        names = {'kf','pg'};
        
        for i_par = 1:numel(names)
            val = par.( names{i_par} );
            if ~isempty( val )
                val_i = pchip(dist, val ,dist_int);
                if closed
                    val_i(end) = val_i(1);
                end
                par.( names{i_par} ) = val_i;
            end
        end
    else
        par = [];
    end
    
    % Update the values positions, segments and parameters in the current
    % track.
    h_track(1,1).positions = pos_int;
    h_track(1,1).segment_index = segment_index_int;
    h_track(1,1).Plength = max_dist;
    h_track(1,1).par = par;
    
    if closed
        h_track(1,1).positions(:,end) = h_track(1,1).positions(:,1);
    end
    h_track(1,1).compute_directions;

end
end