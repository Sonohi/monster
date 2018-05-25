function [ dirs ] = valid_turns( x0, y0, road_index, roads )
% VALID_TURNS = the legal directions the car can go
%
%  x0 = the car's current x coord.
%  y0 = the car's current y coord.
%  road_index = the index of the road the car is on
%  roads = the road map
%
%  dirs = the legal directions

% the direction the road the car is on
dirs = roads(5, road_index);

% add the next crossing
[xc, yc, crossing_road] = next_crossing(x0, y0, road_index, roads);
if (crossing_road == 0),
    return;
end
dirs = [dirs roads(5, crossing_road)];

end