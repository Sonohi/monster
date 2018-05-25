function [ x, y, t ] = switch_lane ( x0, y0, speed, direction, right, lane_width, timestep )

% find the new direction
dir = direction + pi / 4;
if (right),
    dir = dir - pi / 2;
end

% first step
[x(1) y(1)] = move(x0, y0, dir, speed, timestep);
t = 1;

% go on until you are in the next lane
while (dist_2d(x0, y0, x(t), y(t))  < lane_width * sqrt (2)),
    [x(t + 1) y(t + 1)] = move(x(t), y(t), dir, speed, 0.001);
    t = t + 1;
end

end