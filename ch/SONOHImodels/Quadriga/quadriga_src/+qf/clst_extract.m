function val_clst = clst_extract( val_full, num_subpath, ind_cluster )
%CLST_EXTRACT Extracts the subpath values 
% 
% Input:
%   val_full        Data for each cluster [ N x  sum(num_subpath) x O ]
%   num_subpath     Number of subpaths per cluster [ 1 x L ]
%   ind_cluster     Cluster index [ 1 ]
%
% Output:
%   val_clst        Data for each subpath [ N x  M x O ]
%
% M is the number od subpaths for the selected cluster

st = sum( num_subpath( 1:ind_cluster-1 ) )+1;
en = st + num_subpath(ind_cluster)-1;
val_clst = val_full( :,st:en,:,:,: );

end
