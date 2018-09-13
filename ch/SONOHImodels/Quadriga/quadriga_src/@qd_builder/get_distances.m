function dist = get_distances( h_builder )
%GET_DISTANCES Calculates the distances between Rx and Tx
%
% Calling object:
%   Single object
%
% Output:
%   dist
%   A vector containing the distances between each Rx and the Tx in [m]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_builder ) > 1
    error('QuaDRiGa:qd_builder:ObjectArray','??? "calc_scatter_positions" is only defined for scalar objects.')
else
    h_builder = h_builder(1,1); % workaround for octave
end

dist = sqrt( (h_builder.rx_positions(1,:) - h_builder.tx_position(1) ).^2 +...
    ( h_builder.rx_positions(2,:) - h_builder.tx_position(2) ).^2 );

end
