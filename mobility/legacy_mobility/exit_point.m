function [ x, y ] = exit_point( building, side, wall_distance )
% EXIT_POINT = find the exit of a building on a specific side
%
%  building = building side coordinates
%  side = the chosen side
%  wall_distance = the distance from the building
%
%  x = x coord.
%  y = y coord.


% find sides
sides = zeros(4, 4);
sides(:, 1) = [building(3), building(4),  building(1), building(4)];
sides(:, 2) = [building(1), building(4),  building(1), building(2)];
sides(:, 3) = [building(1), building(2),  building(3), building(2)];
sides(:, 4) = [building(3), building(2),  building(3), building(4)]; 

% median point of the building side
x = (sides(1, side) + sides(3, side)) / 2;
y = (sides(2, side) + sides(4, side)) / 2;

% add distance
if(abs(sides(1, side) - x) < 0.5)
    x = x + wall_distance * sign (side - 2);
else
    y = y + wall_distance * sign (side - 2);
end

end
