function ds = calc_delay_spread_coeff( cf, dl )

L = size( cf,3 );
S = size( cf,4 );
p = permute( abs(cf).^2 , [3,4,1,2] );
p = sum( reshape( p, L, S, [] ) , 3 );
p = p./( ones(L,1)* sum(p,1) );
d = permute( dl , [3,4,1,2] );
d = mean( reshape( d, L,S, [] ) , 3 );
ds = sqrt( sum(p.*d.^2,1) - sum(p.*d,1).^2 );

end
