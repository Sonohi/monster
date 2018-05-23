function [ is1n, is1o, is2o, isn, iso ] = find_overlapping_snapshots( h_channel, ic1, ic2, overlap, seg_ind )
%FIND_OVERLAPPING_SNAPSHOTS Tinds the overlapping snapshot indices of the two channelsegments
%
% Two tracks overlap as in the following example ( x = snapshot )
%
%                 1  2  3  4  5  6  7  8
%   Track 1:      x  x  i  x  x  x  x  x                <-- i = initial position
%   Track 2:                  x  x  x  x  i  x  x       <-- i = initial position
%                             1  2  3  4  5  6  7
%
%
% Input:
%   h_channel
%   An [ 1 x N ] array of channel objects obtained from "qd_builder".
%
%   ic1
%   Index of the current segment [ 1 x 1 ]
%
%   ic2
%   Index of the second segment that overlaps with the current one  [ 1 x 1 ]
%
%   overlap
%   The overlapping fraction
%
%   seg_ind
%   The index-list of the sgements [ N x 1 ]
%
% Output:
%   is1n
%   The non-overlapping part of the first segment ranging from the initial position of the
%   first segment to the beginning of the overlappig part. Example: [ 3,4 ]
%
%   is1o
%   The overlapping part of the first segment. Example: [ 5,6,7,8 ]
%
%   is2o
%   The overlapping part of the second segment. Example: [ 1,2,3,4 ]
%
%   isn
%   The snapshot indices of the non-overlapping part in the output channel
%
%   iso
%   The snapshot indices of the overlapping part in the output channel
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% Parses the channel names if "seg_ind" is not given
if ~exist( 'seg_ind','var' ) || isempty( seg_ind )
    [ ~, seg_ind, order ] = parse_channel_names( h_channel );
    h_channel = h_channel( 1,order );           % Order channels to match the names
end

% Track 2 overlapping start and end-points
if ~isempty( ic2 )
    t2o_end   = h_channel( 1,ic2 ).initial_position - 1;
    t2o_start = floor( t2o_end - (t2o_end-1) * overlap + 0.1 );
    is2o = t2o_start : t2o_end;
    
    % Number of overlapping snapshots
    num_overlap = t2o_end - t2o_start + 1;
else
    num_overlap = 0;
    is2o = [];
end

% Track 1 overlapping start and end-points
t1o_end   = h_channel( 1,ic1 ).no_snap;
t1o_start = t1o_end - num_overlap + 1;
if ~isempty( ic2 )
    is1o = t1o_start : t1o_end;
else
    is1o = [];
end

% Track 1 non-overlapping start and end-points
t1n_end   = t1o_start - 1;
t1n_start = h_channel( 1,ic1 ).initial_position;
if t1n_end >= t1n_start
    is1n = t1n_start : t1n_end;
else
    is1n = [];
end

% Find the track in the channel objects
current_trk = seg_ind( ic1 );            % Current  track index
trk_ind = seg_ind == current_trk;       % Indices that blong to the current track
i_seg = sum( trk_ind( 1:ic1 ) );         % Current segment

% Output starting point
if i_seg == 1
    c_start = 1;
else
    trk_ind(ic1:end) = false;
    c_start = sum( cat(1,h_channel(1, trk_ind ).no_snap) - cat(1,h_channel(1, trk_ind ).initial_position)+1 ) + 1;
end

% Output channel non-overlapping indices
if ~isempty( is1n )
    cn_end = c_start + numel( is1n ) - 1;
    isn = c_start : cn_end;
else
    cn_end = c_start - 1;
    isn = [];
end

% Output channel overlapping indices
co_start = cn_end + 1;
co_end   = co_start + num_overlap - 1;
if co_end >= co_start
    iso = co_start : co_end;
else
    iso = [];
end

end
