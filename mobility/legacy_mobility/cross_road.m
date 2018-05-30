function [ x, y, t ] = cross_road ( x0, y0, speed, direction, road_width, timestep )

% first step
[x(1), y(1)] = move(x0, y0, direction, speed, timestep);
t = 1;

% go on until you are on the other side
while (dist_2d(x0, y0, x(t), y(t)) < road_width),
    [x(t + 1), y(t + 1)] = move(x(t), y(t), direction, speed, timestep);
    t = t + 1;
end
