function [ xc, yc, crossing_road ] = next_crossing( x0, y0, road_index, roads )
% VALID_TURNS = the legal directions the car can go
%
%  x0 = the car's current x coord.
%  y0 = the car's current y coord.
%  road_index = the index of the road the car is on
%  roads = the road map
%
%
%  xc = the x coord. of the center of the crossing
%  yc = the y coord. of the center of the crossing
%  crossing_road = the crossing_road of the crossing road

% find intersections with the current road

% initialize
crossing_road = 0;
road = roads(:, road_index);
others = roads;
others(:, road_index) = [];
dir = road(5);
x = x0;
y = y0;

% find the intersecting road
while (crossing_road == 0 && x >= road(1) && y >= road(2) && x <= road(3) && y <= road(4)),
    x = x + 5 * cos(dir);
    y = y + 5 * sin(dir);
    [cross, crossing_road] = find_road(x, y, others);
end

% move forward the index for the removed road
if(road_index <= crossing_road),
    crossing_road = crossing_road + 1;
end

if (crossing_road == 0),
    % there are no intersections
    xc = x0;
    yc = y0;
else
    % middle lines of the two roads
    prev_mid = [road(1) + abs(sin(dir)) * (road(3) - road(1)) / 2 road(2) + abs(cos(dir)) * (road(4) - road(2)) / 2 road(3) - abs(sin(dir)) * (road(3) - road(1)) / 2 road(4) - abs(cos(dir)) * (road(4) - road(2)) / 2];
    next_mid = [cross(1) + abs(sin(roads(5,crossing_road))) * (cross(3) - cross(1)) / 2 cross(2) + abs(cos(roads(5,crossing_road))) * (cross(4) - cross(2)) / 2 cross(3) - abs(sin(roads(5,crossing_road))) * (cross(3) - cross(1)) / 2 cross(4) - abs(cos(roads(5,crossing_road))) * (cross(4) - cross(2)) / 2];
    
    
    pm = median(prev_mid);
    nm = median(next_mid);
    
    if (mod(dir, pi) < 0.1),
        xc = nm;
        yc = pm;
    else
        xc = pm;
        yc = nm;
    end
end

end