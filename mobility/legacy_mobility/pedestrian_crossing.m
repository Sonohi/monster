function [ x, y, t, crossing, dir ] = pedestrian_crossing ( x0, y0, xf, yf, speed, building, road_width, turn_pause, crossing_pause, prev_dir, timestep )
% PEDESTRIAN_CROSSING = choose the best direction and cross the road if necessary
%
%  x0 = starting point x coordinate
%  y0 = starting point y coordinate
%  xf = arrival point x coordinate
%  yf = arrival point y coordinate
%  speed = speed (in m/s)
%  building = coordinates of the current building
%  road_width = the width of the road
%  turn_pause = pause when changing direction (in timesteps)
%  crossing_pause = maximum pause before crossing (in timesteps)
%  prev_dir = the direction the pedestrian came from
%  timestep = time step in seconds
%
%  x = trajectory (x coord.)
%  y = trajectory (y coord.)
%  t = crossing time (in ms)
%  crossing = true if the pedestrian crosses
%  dir = direction

crossing_pause = randi(crossing_pause);
crossing = false;

% find the corner
corner = [-1 -1];
if (x0 >= max([building(1) building(3) building(5) building(7)])),
    corner(1) = 1;
end
if (y0 >= max([building(2) building(4) building(6) building(8)])),
    corner(2) = 1;
end

% find the optimal direction
dir = 0;
best_dir = 0;
best_dist = 1E9;
for (i = 1 : 4),
    dir = dir + pi / 2;
    [x, y] = move(x0, y0, dir, speed, 0.1);
    dist = dist_2d(x, y, xf, yf);
    if (dist < best_dist && abs(dir - pi - prev_dir) > 0.1)
        best_dist = dist;
        best_dir = dir;
    end
end
dir = best_dir;

% first step
x(1) = x0;
y(1) = y0;

% cross or stay

if ((dir == pi / 2 && corner(2) > 0) || (dir == 2 * pi && corner(1) > 0) || (dir == 3 * pi / 2 && corner(2) < 0) || (dir == pi && corner(1) < 0)),
    [x, y, t] =  cross_road ( x0, y0, speed, dir, road_width, timestep );
    t = t + crossing_pause;
    x = [ones(1, crossing_pause) * x0 x];
    y = [ones(1, crossing_pause) * y0 y];
    crossing = true;
else
    x = ones(1, turn_pause) * x0;
    y = ones(1, turn_pause) * y0;
    t = turn_pause;
end

end
