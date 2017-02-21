function [ pathloss, step ] = load_power ( filename )
% LOAD_ROADS = load pathloss map from a txt file
%
%  pathloss = vector with pathloss values

transmitted = 13;
pathloss = dlmread(filename,',')';
pathloss(4, :) = 10 * log10(pathloss(4, :)) - transmitted;
delta = [0 pathloss(1, 1 : end - 1)];
step = max(pathloss(1, :) - delta);

end
