function [ adjacent ] = adjacent_corners( corners, x0, y0 )
% ADJACENT_CORNERS = find the corners that are reacheable from x0, y0
%
%  corners = corner matrix
%  x0 = current x coord.
%  y0 = current y coord.
%
%  adjacent = reachable corners

adjacent = zeros(2, 2);
j = 1;

for (i = 1 : 4),
    if(dist_2d(x0, y0, corners(1, i), corners(2, i)) > 1),
        side_distance = min([abs(x0 - corners(1, i)) abs(y0 - corners(2, i))]);
        if (side_distance < 1),
            adjacent(:, j) = corners(:, i);
            j = j + 1;
        end
    end
end

adjacent(:, j : end) = [];

end