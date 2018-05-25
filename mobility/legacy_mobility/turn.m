function [ x, y, t ] = turn ( x0, y0, speed, direction, right, turn_radius, timestep )

% turn parameters
turn_speed = 5;
brake_distance = 5;

% first step
x(1) = 0;
y(1) = 0;

dir = 0;
% brake
t_brake = 2 * brake_distance / (turn_speed + speed);
a = (turn_speed - speed) / t_brake;
for (t = 1 : t_brake / timestep),
    speed = speed + a * timestep;
    [x(t + 1), y(t + 1)] = move(x(t), y(t), dir, speed, timestep);
end

% turn
t_turn = turn_radius * pi / (2 * turn_speed);
for (t = t_brake / timestep + 1 : (t_turn + t_brake) / timestep),
    tau = round(t);
    dir = - pi * (tau + 1 - t_brake / timestep) / (2 * t_turn / timestep);
    [x(tau + 1), y(tau + 1)] = move(x(tau), y(tau), dir, turn_speed, timestep);
end
dir = -pi/2;

% accelerate
for (t = (t_turn + t_brake) / timestep + 1 : (t_turn + 2 * t_brake) / timestep),
    tau = round(t);
    speed = speed - a * timestep;
    [x(tau + 1), y(tau + 1)] = move(x(tau), y(tau), dir, turn_speed, timestep);
end
    
% if it's a left turn, invert the y axis
if (~right),
    y = -y;
end

% rotate and add offset
[x, y] = rotate(x, y, direction);
x = x + x0;
y = y + y0;

end
