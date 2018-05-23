function ic2 = find_overlapping_segment( h_channel, ic1, seg_ind )
%FIND_OVERLAPPING_SEGMENT Finds the oferlapping segment of a channel
%
% Input:
%   h_channel
%   An [ 1 x N ] array of channel objects obtained from "qd_builder".
%
%   ic1
%   Index of the current segment [ 1 x 1 ]
%
%   seg_ind
%   The index-list of the sgements [ N x 1 ]
%
% Output:
%   ic2
%   Index of the segment that overlaps with the current one  [ 1 x 1 ]
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

current_trk = seg_ind( ic1 );           % Current  track index
trk_ind = seg_ind == current_trk;       % Indices that blong to the current track
n_seg = sum( trk_ind );                 % Number of segments belonging to the current track
i_seg = sum( trk_ind( 1:ic1 ) );        % Current segment

% Is the track closed?
i_first_seg = find( trk_ind,1 );
if h_channel( 1,i_first_seg ).initial_position > 1
    closed = true;
else
    closed = false;
end

% This determines the the start and end-segments for closed tracks
if i_seg < n_seg && h_channel(1,ic1).no_snap > 1
    ic2 = find( trk_ind(ic1+1:end) , 1 ) + ic1;
elseif closed
    ic2 = i_first_seg;
else
    ic2 = [];
end

end
