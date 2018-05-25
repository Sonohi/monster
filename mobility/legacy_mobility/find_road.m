function [ road road_index ] = find_road( x0, y0, roads )
% VALID_TURNS = the legal directions the car can go
%
%  x0 = the car's current x coord.
%  y0 = the car's current y coord.
%  roads = the road map
%
%  road = the road the car is on
%  road_index = the road number

road_index = 0;
road = [];

% find the road the car is on
for (i = 1 : length(roads(1, :))),
    if (x0 >= roads(1, i) && y0 >= roads(2, i) && x0 <= roads(3, i) && y0 <= roads(4, i)),
        road_index = i;
        road = roads(:, i);
        break;
    end
end

% the car is off-road!
if (road_index == 0),
    return;
end

end