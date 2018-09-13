function [ gain_dBi, pow_max ] = calc_gain( h_qd_arrayant, i_element )
%CALC_GAIN Calculates the gain in dBi of the array antenna
%
% Calling object:
%   Single object
%
% Input:
%   i_element
%   A list of element indices.
%
% Output:
%   gain_dBi
%   Normalized Gain of the antenna in dBi.
%
%   pow_max
%   Maximum power in main beam direction in dBi.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_qd_arrayant ) > 1 
   error('QuaDRiGa:qd_arrayant:calc_gain','calc_gain not definded for object arrays.');
else
    h_qd_arrayant = h_qd_arrayant(1,1); % workaround for octave
end

if nargin == 1
    i_element = 1:h_qd_arrayant.no_elements;
end

if ~(any(size(i_element) == 1) && isnumeric(i_element) ...
        && isreal(i_element) && all(mod(i_element, 1) == 0) && all(i_element > 0))
    error('??? "i_element" must be integer and > 0')
elseif any(i_element > h_qd_arrayant.no_elements)
    error('??? "i_element" exceed "no_elements"')
end

[~, elev_grid] = meshgrid(h_qd_arrayant.azimuth_grid, h_qd_arrayant.elevation_grid);
gain_dBi = zeros(numel(i_element),1);
pow_max = zeros(numel(i_element),1);

for n = 1 : numel(i_element)
    
    % Read the qd_arrayant elements
    Fa = h_qd_arrayant.Fa(:, :, i_element(n));
    Fb = h_qd_arrayant.Fb(:, :, i_element(n));
    
    % calculate radiation power pattern
    P = abs(Fa).^2 + abs(Fb).^2;
    
    % Normalize by max value
    P_max = max( P(:) );
    P = P ./ P_max;
    
    % Calculate Gain
    tmp         = cos(elev_grid(:));
    gain_lin    = sum(tmp) ./ sum(P(:).*tmp);
    
    gain_dBi(n) = 10*log10(gain_lin);
    pow_max(n) = 10*log10(P_max);
end

end

