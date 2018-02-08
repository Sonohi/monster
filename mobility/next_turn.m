function [ x, y, t, path ] = next_turn (x0, y0, xf, yf, speed, lane, road, roads, lane_width, timestep)
% NEXT_TURN = pass the next intersection
%
%  x0 = starting point x coordinate
%  y0 = starting point y coordinate
%  xf = end point x coordinate
%  yf = end point y coordinate
%  speed = speed (in m/s)
%  lane = the current lane
%  road = the index of the current road
%  roads = road map
%  lane_width = the width of a lane
%
%  x = trajectory (x coord.)
%  y = trajectory (y coord.)
%  t = movement time (in ms)
%  path = the path through the intersection

% initialize and find possible directions
current_dir = roads(5, road);
possible_dirs = valid_turns(x0, y0, road, roads);
[xc, yc, crossing_road] = next_crossing(x0, y0, road, roads);
if(crossing_road == 0),
    x = [];
    y = [];
    t = 0;
    path = [];
    return;
end

% find the best direction
best_dir = 0;
min_distance = 1E9;
for (i = 1 : length(possible_dirs)),
    dir = possible_dirs(i);
    [x, y] = move(xc, yc, dir, speed, 0.1);
    dist = dist_2d(x, y, xf, yf);
    if (dist <  min_distance && abs(dir - current_dir) ~= pi),
        best_dir = dir;
        min_distance = dist;
    end
end

dir = best_dir;

if (dir == 0),
    dir = 2 * pi;
end
if (current_dir == 0),
    current_dir = 2 * pi;
end

t = 1;
x(1) = x0;
y(1) = y0;

path = [];

if(dir == current_dir)
    % get past the crossing
    [xs, ys, tau] = straight(x0, y0, xc + lane_width * lane * sin(dir), yc - lane_width * lane * cos(dir), speed, timestep);
    t = t + tau;
    x = [x xs];
    y = [y ys];
    return;
end

right = false;
if (abs(dir - mod(current_dir, 2 * pi) - pi / 2) < 1),
    % switch lanes if necessary
    while (lane > -1),
        [xs, ys, tau] = switch_lane ( x(t), y(t), speed, current_dir, right, lane_width, timestep);
        lane = lane - 1;
        t = t + tau;
        x = [x xs];
        y = [y ys];
        path = [path; road lane];
    end
else if (dir ~= current_dir),
        % switch lanes if necessary
        right = true;
        while (lane < 1),
            [xs, ys, tau] = switch_lane ( x(t), y(t), speed, current_dir, right, lane_width, timestep);
            lane = lane + 1;
            t = t + tau;
            x = [x xs];
            y = [y ys];
            path = [path; road lane];
        end
    end
end

% turn
xi = xc - (5 + 1.5 * lane_width) * cos(current_dir) + lane * lane_width * sin(current_dir);
yi = yc - (5 + 1.5 * lane_width) * sin(current_dir) - lane * lane_width * cos(current_dir);
[xs, ys, tau] = straight(x(t), y(t), xi, yi, speed);
t = t + tau;
x = [x xs];
y = [y ys];
[xs, ys, tau] = turn(xi, yi, speed, current_dir, right, lane_width / 2, timestep);
t = t + tau;
x = [x xs];
y = [y ys];
road = crossing_road;
path = [path; road lane];

end