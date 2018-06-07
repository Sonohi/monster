function [ corners ] = add_walldist( building, wall_distance)
% ADD_WALLDIST = add a distance from the wall to a building profile
%
%  building = the building corners
%  wall_distance = the walking distance from the wall
%
%  corners = a matrix with the corner coordinates

corners = zeros(2, 4);
corners(1,1) = min([building(1) building(3) building(5) building(7)]);
corners(1,2) = max([building(1) building(3) building(5) building(7)]);
corners(1,3) = min([building(1) building(3) building(5) building(7)]);
corners(1,4) = max([building(1) building(3) building(5) building(7)]);

corners(2,1) = min([building(2) building(4) building(6) building(8)]);
corners(2,2) = min([building(2) building(4) building(6) building(8)]);
corners(2,3) = max([building(2) building(4) building(6) building(8)]);
corners(2,4) = max([building(2) building(4) building(6) building(8)]);

corners(:, 1) = corners(:, 1) + [-1; -1] * 0.5;
corners(:, 2) = corners(:, 2) + [1; -1] * 0.5;
corners(:, 3) = corners(:, 3) + [-1; 1] * 0.5;        
corners(:, 4) = corners(:, 4) + [1; 1] * 0.5;

end
