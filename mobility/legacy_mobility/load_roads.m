function [ roads ] = load_roads ( filename )
% LOAD_ROADS = load road model from a txt file
%
%  roads = vector with the road limits

corners = dlmread(filename,',')';
roads = zeros(5, length(corners(1, :)));
roads(1 : 4, :) = corners(1 : 4, :);

for (i = 1 : length(corners(1, :))),
    roads(5, i) = mod(2 * pi + pi * min(0, corners(6, i)) + pi / 2 * corners(5, i), 2 * pi);
    if (roads(5, i) == 0),
        roads(5, i) = 2 * pi;
    end
end

end