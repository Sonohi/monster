function correct_overlap( h_track, overlap )
%CORRECT_OVERLAP Corrects positions of the segment start to account for the overlap.
%
% Calling object:
%   Object array
%
% Description:
%   After the channel coefficients are calculated, adjacent segments can be merged into a time-
%   continuous output. The merger assumes that the merging interval happens at the end of one
%   segment, before a new segments starts. In reality, however, the scenario change happens in
%   the middle of the overlapping part (and not at the end of it). This function corrects the
%   position of the segment start to account for that.
%
% Input:
%   overlap
%   The length of the overlapping part relative to the segment length. It can have values in
%   between 0 (no overlap) and 1 (ramp along the entire segment). The default value is 0.5. You
%   need to make sure that the same value is used when calling "qd_channel.merge".
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% Parse input arguments
check = true;
if nargin < 2
    overlap = 0.5;
    check = false;
end

if check
    if ~( isnumeric(overlap) && all(size(overlap) == [1 1]) && isreal(overlap) ...
            && overlap<=1 && overlap>=0 )
        error('??? Overlap must be scalar, and in between 0 and 1')
    end
end

if numel(h_track) > 1
    
    sic = size( h_track );
    prc = false( sic );
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            correct_overlap( h_track(i1,i2,i3,i4), overlap );
            prc( qf.eqo( h_track(i1,i2,i3,i4), h_track ) ) = true;
        end
    end
    
else
    % Only do if there are more than on segment
    if h_track(1,1).no_segments > 1
        % Get a list of the segment indices
        seg_ind_old = [ h_track(1,1).segment_index , h_track(1,1).no_snapshots ];
        seg_ind_new = zeros( size(  h_track(1,1).segment_index ));
        seg_ind_new(1) = 1;

        for n = 1:h_track(1,1).no_segments-1
            seg_length = seg_ind_old(n+1) - seg_ind_new(n);
            overlapping = seg_length * overlap;
            new_seg_length = round( seg_length + 0.588235*overlapping );
            
            if seg_ind_new(n) + new_seg_length < seg_ind_old(n+2)
                seg_ind_new(n+1) = seg_ind_new(n) + new_seg_length;
            else
                seg_ind_new(n+1) = seg_ind_old(n+1);
            end
        end
        
        % Assign new segment index
        h_track(1,1).segment_index = seg_ind_new;
    end
end

end