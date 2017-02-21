function [ buildings ] = load_buildings( filename )
% LOAD_BUILDINGS = load building model from a txt file
%
%  buildings = vector with the building corners

corners = dlmread(filename,',')';
buildings = zeros(8, length(corners(1, :)));

for (i = 1 : length(corners(1, :))),
    buildings(:, i) = [corners(1, i) corners(2, i) corners(1, i) corners(4, i) corners(3, i) corners(2, i) corners(3, i) corners(4, i)];
end

end
