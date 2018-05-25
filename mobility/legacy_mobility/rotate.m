function [ x, y ] = rotate ( x0, y0, psi )
% ROTATE = rotation by an angle psi
%
%  x0 = unrotated x coordinate vector
%  y0 = unrotated y coordinate vector
%
%  x = rotated x coordinate vector
%  y = rotated y coordinate vector

[theta, rho] = cart2pol(x0, y0);
theta = theta + psi;
[x, y] = pol2cart(theta, rho);

end
