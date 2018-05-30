function [ x, y, t ] = straight( x0, y0, xf, yf, speed, timestep)
% STRAIGHT = move in a straight line between two points
%
%  x0 = starting point x coordinate
%  y0 = starting point y coordinate
%  xf = end point x coordinate
%  yf = end point y coordinate
%  speed = speed (in m/s)
%
%  x = trajectory (x coord.)
%  y = trajectory (y coord.)
%  t = movement time (in ms)

T_ms = floor(1 / timestep * dist_2d(x0, y0, xf, yf) / speed);

x = zeros(1, T_ms);
y = zeros(1, T_ms);

dir = cart2pol(xf - x0, yf - y0);

[x(1), y(1)] = move(x0, y0, dir, speed, timestep);

for (t_ms = 2 : T_ms),
    [x(t_ms), y(t_ms)] = move(x(t_ms - 1), y(t_ms - 1), dir, speed, timestep);
end

t = T_ms;

end
