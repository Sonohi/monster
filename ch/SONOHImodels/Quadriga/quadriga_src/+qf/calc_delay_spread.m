function [ ds, mean_delay ] = calc_delay_spread( taus, pow )
%CALC_ANGULAR_SPREADS Calculates the delay spread in [s]
%
% This function calculates the delay spread from a given set of delays and powers. 
% 
% Input: 
%    taus  A vector of deays [s]. Dimensions: n_taus x n_path
%    pow   A vector of path powers in [W]. Dimensions: n_taus x n_path
% 
% Output:
%    ds    The RMS delay spread for each delay vector. Dimensions: n_taus x 1
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

N = size( taus,1 );
if size( pow,1 ) < N
    pow = pow( ones(1,N), : );
end

% Normalize powers
pt = sum( pow,2 );
pow = pow./pt( :,ones(1,size(pow,2))  );

mean_delay = sum( pow.*taus,2 ); 

tmp = taus - mean_delay(:,ones( 1,size(taus,2) ) );

ds = sqrt( sum(pow.*(tmp.^2),2) - sum( pow.*tmp,2).^2 );

end
