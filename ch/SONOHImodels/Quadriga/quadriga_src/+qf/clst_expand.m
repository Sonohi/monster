function val_subpath = clst_expand( val_cluster, num_subpath )
%CLST_EXPAND Copies the cluster values to subpath values
% 
% Input:
%   val_cluster     Data for each cluster [ N x L x M ]
%   num_subpath     Number of subpaths per cluster [ 1 x L ]
%
%   M = max muber of subpaths
%   Only the first values are used. 
%   E.g.: M = 20, num_subpath(l) = 3 --> use first 3 values from third dimension.
%
% Output:
%   val_subpath     Data for each subpath [ N x  sum(num_subpath) ]

[N,L,M] = size( val_cluster );

expand_only = true;
if M == max( num_subpath )
    expand_only = false;
end

val_subpath = zeros( N,sum(num_subpath) );

ls = 1;
for l = 1:L
    le = ls + num_subpath(l) - 1;
    if expand_only
        val_subpath( :,ls:le ) = val_cluster( : , l*ones(1,num_subpath(l)) );
    else
        val_subpath( :,ls:le ) = val_cluster( : , l , 1:num_subpath(l) );
    end
    ls = le + 1;
end

end
