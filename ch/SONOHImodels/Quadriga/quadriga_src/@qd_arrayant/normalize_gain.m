function gain_dBi = normalize_gain( h_qd_arrayant, i_element, gain )
%NORMALIZE_GAIN Normalizes all patterns to their gain
%
% Calling object:
%   Single object
%
%
% Input:
%   i_element
%   A list of elements for which the normalization is done. Default: All elements
%
%   gain
%   The gain that should be set in the pattern. If this variable is not given, the gain is
%   calculated from the pattern
%
% Output:
%   gain_dBi
%   Normalized gain of the antenna
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

if ~exist('i_element','var') || isempty( i_element )
    i_element = 1:h_qd_arrayant.no_elements;
end

if ~exist('gain','var') || isempty( gain )
    gain = NaN(1,numel(i_element));
elseif numel(gain) == 1
    gain = ones(1,numel(i_element))*gain;
elseif numel(gain) ~= numel(i_element)
    error('The number of gain values must either be 1 or match the numebr of elements.')
end

if ~(any(size(i_element) == 1) && isnumeric(i_element) ...
        && isreal(i_element) && all(mod(i_element, 1) == 0) && all(i_element > 0))
    error('??? "i_element" must be integer and > 0')
elseif any(i_element > h_qd_arrayant.no_elements)
    error('??? "i_element" exceed "no_elements"')
end

[~, elev_grid] = meshgrid(h_qd_arrayant.azimuth_grid, h_qd_arrayant.elevation_grid);
gain_dBi = zeros(numel(i_element),1);

for n = 1 : numel(i_element)
    
    % Read the element patterns
    Fa = h_qd_arrayant.Fa(:, :, i_element(n));
    Fb = h_qd_arrayant.Fb(:, :, i_element(n));
    
    % calculate radiation power pattern
    P = abs(Fa).^2 + abs(Fb).^2;
    
    % Normalize by max value
    P_max = max( P(:) );
    P = P ./ P_max;
    
    % Calculate Gain
    tmp         = cos(elev_grid(:));
    
    if isnan( gain(n) )
        gain_lin    = sum(tmp) ./ sum(P(:).*tmp);
    else
        gain_lin    = 10.^(0.1*gain(n));
    end

    gain_dBi(n) = 10*log10(gain_lin);
    
    % Normalize Patterns by their gain
    tmp = sqrt(gain_lin./P_max);
    h_qd_arrayant.Fa(:, :, i_element(n)) = Fa .* tmp;
    h_qd_arrayant.Fb(:, :, i_element(n)) = Fb .* tmp;
end

end
