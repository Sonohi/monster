function [ pathloss ] = pathloss ( x, y, pathloss_map, step )
% PATHLOSS = find the pathloss vector
%
%  x = x coord. vector
%  y = y coord. vector
%  pathloss_map = pathloss map
%  step = map quantization step
%
%  pathloss = pathloss vector for the given trajectory

% initialization
pathloss = zeros(1, length(x));
tic
for (i = 1 : length(x)),
    if (x(i) < 0),
	x(i) = 0;
    end
    if (y(i) < 0),
	y(i) = 0;
    end
    dist_x = abs(x(i) - pathloss_map(1, :));
    [close_x, close_x] = find(dist_x < step);
    dist_y = abs(y(i) - pathloss_map(2, :));
    [close_y, close_y] = find(dist_y < step);
    points = intersect(close_x, close_y);
    total_weight = 0;
    for (j = 1 : length(points)),
        weight = step * sqrt(2) - dist_2d(x(i), y(i), pathloss_map(1, points(j)), pathloss_map(2, points(j)));
        pathloss(i) = pathloss(i) + pathloss_map(4, points(j)) * weight;
        total_weight = total_weight + weight;
    end
    pathloss(i) = pathloss(i) / total_weight;
end
toc
end
