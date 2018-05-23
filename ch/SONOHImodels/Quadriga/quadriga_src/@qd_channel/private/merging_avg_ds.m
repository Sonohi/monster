function [ ds, p, d ] = merging_avg_ds( cf, dl )
%CALC_DS Calculates the DS
%
% Input:
%   cf          Coefficients                    [ R x T x L x S ]
%   dl          Delays                          [ R x T x L x S ]
%
% Output: 
%   ds          Average DS                      [ 1 x 1 ]
%   p           Avergae normalized path-power   [ L x 1 ]
%   d           Avergae normalized path-delay   [ L x 1 ]

L = size( cf,3 );

p = permute( abs(cf).^2 , [3,1,2,4] );
p = mean( reshape( p, L, [] ) , 2 );
pn = p./sum(p,1);

d = permute( dl , [3,1,2,4] );
d = mean( reshape( d, L, [] ) , 2 );

ds = sqrt( sum(pn.*d.^2,1) - sum(pn.*d,1).^2 );

end
