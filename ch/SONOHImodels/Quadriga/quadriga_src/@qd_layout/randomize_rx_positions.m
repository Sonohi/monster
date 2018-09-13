function randomize_rx_positions( h_layout, max_dist, min_height, max_height, track_length, rx_ind )
%RANDOMIZE_RX_POSITIONS Generates random Rx positions and tracks. 
%
% Calling object:
%   Single object
%
% Description:
%   Places the users in the layout at random positions. Each user will be assigned a linear track
%   with random direction. The random height of the user terminal will be in between 'min_height'
%   and 'max_height'.
%
% Input:
%   max_dist
%   the maximum distance from the layout center in [m]. Default is 50 m.
%
%   min_height
%   the minimum user height in [m]. Default is 1.5 m.
%
%   max_height
%   the maximum user height in [m]. Default is 1.5 m.
%
%   track_length
%   the length of the linear track in [m]. Default is 1 m.
%
%   rx_ind
%   a vector containing the receiver indices for which the positions should be generated. Default:
%   All receivers
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_layout ) > 1 
   error('QuaDRiGa:qd_layout:randomize_rx_positions','randomize_rx_positions not definded for object arrays.');
else
    h_layout = h_layout(1,1); % workaround for octave
end


% Parse input variables
if ~exist( 'max_dist' , 'var' ) || isempty( max_dist )
    max_dist = 50;
elseif ~( all(size(max_dist) == [1 1]) &&...
        isnumeric(max_dist) &&...
        isreal(max_dist) &&...
        max_dist > 0 )
    error('??? "max_dist" must be a real scalar  > 0')
end

if ~exist( 'min_height' , 'var' ) || isempty( min_height )
    min_height = 1.5;
elseif ~( all(size(min_height) == [1 1]) &&...
        isnumeric(min_height) &&...
        isreal(min_height) )
    error('??? "min_height" must be a real scalar')
end

if ~exist( 'max_height' , 'var' ) || isempty( max_height )
    max_height = 1.5;
elseif ~( all(size(max_height) == [1 1]) &&...
        isnumeric(max_height) &&...
        isreal(max_height) )
    error('??? "max_height" must be a real scalar  > 0')
end

if ~exist( 'track_length' , 'var' ) || isempty( track_length )
    track_length = 1;
elseif ~( all(size(track_length) == [1 1]) &&...
        isnumeric(track_length) &&...
        isreal(track_length) )
    error('??? "track_length" must be a real scalar  > 0')
end

if ~exist( 'rx_ind' , 'var' ) || isempty( rx_ind )
    rx_ind = 1:1:h_layout.no_rx;
elseif islogical( rx_ind )
    rx_ind = find( rx_ind );
end

% Generate random positions and tracks
for i_rx = 1:numel( rx_ind )
    n = rx_ind( i_rx );

    a = (2*rand-1)*max_dist + 1j*(2*rand-1)*max_dist;
    while abs(a)>max_dist
        a = (2*rand-1)*max_dist + 1j*(2*rand-1)*max_dist;
    end
    b = rand * (max_height - min_height) + min_height;
    
    trk = qd_track.generate( 'linear',track_length );
    trk.name = ['Rx',sprintf('%04d',n)];
    trk.initial_position = [ real(a) ; imag(a) ; b ];
    if track_length>0
        trk.interpolate_positions( h_layout.simpar.samples_per_meter );
        trk.compute_directions;
    end
    scenarios = h_layout.track(1,n).scenario(1);
    trk.scenario = scenarios( ones(1,h_layout.no_tx),1 );
    
    % Write new track to layout
    h_layout.track(1,n) = trk;
end

end