function d = dist_2d ( x0, y0, x, y )
% DIST_2D = 2D distance function
%
%  x0 = x coord. (point 1)
%  y0 = y coord. (point 1)
%  x = x coord. (point 2)
%  y = y coord. (point 2)
%
%  d = Euclidean distance

d = sqrt((x - x0) * (x - x0) + (y - y0) * (y - y0));

end
