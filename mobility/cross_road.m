function [ x, y, t ] = cross_road ( x0, y0, speed, direction, road_width )

% first step
[x(1), y(1)] = move(x0, y0, direction, speed, 0.001);
t = 1;

% go on until you are on the other side
while (dist_2d(x0, y0, x(t), y(t)) < road_width),
    [x(t + 1), y(t + 1)] = move(x(t), y(t), direction, speed, 0.001);
    t = t + 1;
end
