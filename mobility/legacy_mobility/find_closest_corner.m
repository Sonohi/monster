function [ index, x, y ] = find_closest_corner( x0, y0, corners )
% FIND_CLOSEST_CORNER = find the corner closest to (x0, y0)
%
%  x0 = x coord. of the point
%  y0 = y coord. of the point
%  corners = matrix with the corner coordinates
%
%  index = index of the closest corner
%  x = x coord. of the closest corner
%  y = y coord. of the closest corner

min_dist = 1E9;
index = 0;

for (i = 1 : length(corners(1, :))),
    distance = dist_2d(x0, y0, corners(1, i), corners(2, i));
    if (distance < min_dist),
        min_dist = distance;
        index = i;
    end
end

x = corners(1, index);
y = corners(2, index);

end
