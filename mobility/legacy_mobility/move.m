function [ x, y ] = move( x0, y0, dir, speed, t )
% MOVE = movement function
%
%  x0 = starting point x coordinate
%  y0 = starting point y coordinate
%  dir = movement direction 
%  speed = speed (in m/s)
%  t = movement time
%
%  x = final point x coordinate
%  y = final point y coordinate

x = x0 + cos(dir) * speed * t;
y = y0 + sin(dir) * speed * t;

end
