function subtracks = get_subtrack( h_track , i_segment )
%GET_SUBTRACK Splits the track in subtracks for each segment (state)
%
% Calling object:
%   Single object
%
% Description:
%   After defining segments along the track, one needs the subtrack that corresponds only to one
%   segment to perform the channel calculation. This new track can consist of two segments. The
%   first segment contains the positions from the previous segment, the second from the current.
%   This is needed to generate overlapping channel segments for the merging process. This function
%   returns the subtracks for the given segment indices. When no input argument is provided, all
%   subtracks are returned.
%
% Input:
%   i_segment
%   A list of indices indicating which subtracks should be returned. By default, all subtracks are
%   returned.
%
% Output:
%   subtracks
%   A vector of qd_track objects corresponding to the number of segments.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_track ) > 1 
   error('QuaDRiGa:qd_track:get_subtrack','get_subtrack not definded for object arrays.');
else
    h_track = h_track(1,1); % workaround for octave
end

if nargin == 1
   i_segment = 1:h_track.no_segments;
   check = false;
else
    check = true;
end

% Parse the input variables
if check
    if ~( any(size(i_segment) == 1) && isnumeric(i_segment) ...
            && isreal(i_segment) && all(mod(i_segment,1)==0) && all(i_segment > 0) )
        error('??? "i_segment" must be integer and > 0')
    elseif max(i_segment) > h_track.no_segments
        error('??? "i_segment" exceeds number of entries in object')
    end
end

% Make a copy of the parameters
par = h_track.par;
names = {'ds','kf','pg','asD','asA','esD','esA','xpr','o2i_loss','o2i_d3din'};

for seg = 1 : numel(i_segment)
    segment = i_segment(seg);
    
    % Select the part of the track that corresponds to the given segment
    if h_track.no_segments == 1
        % The current track has only one segment
        if h_track.closed == 1
            ind = 1:h_track.no_snapshots-1;
        else
            ind = 1:h_track.no_snapshots;
        end
        seg_ind = 1;
        scen_ind = 1;
        
    elseif h_track.no_segments == h_track.no_snapshots
        % Each snapshot has its own segment
        ind = h_track.segment_index( segment );
        seg_ind = 1;
        scen_ind = segment;
        
    elseif segment == 1
        % The current track has more than one segment, and the returned
        % segment is the first one.
        if h_track.closed == 1
            ind = [ h_track.segment_index( h_track.no_segments ) : h_track.no_snapshots-1 ,...
                1:h_track.segment_index( segment+1 )-1 ];
            seg_ind = [ 1 , h_track.no_snapshots-h_track.segment_index( h_track.no_segments )+1 ];
            scen_ind = [ h_track.no_segments , 1 ];
        else
            ind = 1 : h_track.segment_index( segment+1 )-1;
            seg_ind = 1;
            scen_ind = 1;
        end
        
    elseif segment == h_track.no_segments
        % The current track has more than one segment, and the returned
        % segment is the last one.
        if h_track.closed == 1
            ind = h_track.segment_index( segment-1 ) : h_track.no_snapshots-1;
        else
            ind = h_track.segment_index( segment-1 ) : h_track.no_snapshots;
        end
        seg_ind = [ 1 , h_track.segment_index( segment ) - h_track.segment_index( segment-1 ) + 1 ];
        scen_ind = [ segment-1 , segment ];
        
    else
        % The current track has more than one segment, and the returned
        % segment neither the first, nor the last one.
        ind = h_track.segment_index( segment-1 ) : h_track.segment_index( segment+1 )-1;
        seg_ind = [ 1 , h_track.segment_index( segment ) - h_track.segment_index( segment-1 ) + 1 ];
        scen_ind = [ segment-1 , segment ];
        
    end
    
    % Create new track with the corresponding data
    tr = qd_track;
    tr.name                     = [h_track.name,'_',num2str(segment)];
    tr.positions                = h_track.positions( :,ind );
    tr.segment_index            = seg_ind;
    if tr.no_segments == 2
        sp = tr.positions( :, seg_ind(2) );
        tr.scenario = h_track.scenario(:,scen_ind([2,2]));
    else
        sp = tr.positions( :, 1 );
        tr.scenario = h_track.scenario(:,scen_ind);
    end
    
    if ~isempty( h_track.ground_direction )
        tr.ground_direction         = h_track.ground_direction(ind);
        tr.height_direction         = h_track.height_direction(ind);
    end
    
    if ~isempty(par)
        % Init struct
        out_par = struct('ds',[],'kf',[],'pg',[],'asD',[],'asA',[],'esD',[],'esA',[],'xpr',[],'o2i_loss',[],'o2i_d3din', []);
        
        % Copy the data
        for n = 1 : numel( fieldnames( out_par ) )
            val = par.(names{n});
            if ~isempty( val )
                if n==2 || n==3
                    out_par.( names{n} ) = val(:,ind,:);
                else
                    out_par.( names{n} ) = val(:,scen_ind,:);
                end
            end
        end
        
        % Save to subtrack
        tr.par_nocheck = out_par;
    end
    
    % Set the initial position
    tr.initial_position = h_track.initial_position + sp;
    for n=1:3
        tr.positions(n,:) = tr.positions(n,:) - sp(n);
    end
    
    % Append to subtracks-list
    if numel( i_segment ) == 1
        subtracks = tr;
    else
        subtracks(seg) = tr;
    end
end
end

