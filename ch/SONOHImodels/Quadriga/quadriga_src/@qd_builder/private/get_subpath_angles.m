function [ aod,eod,aoa,eoa,delay ] = get_subpath_angles( h_builder,i_mobile )
%GET_SUBPATH_ANGLES Generate subpaths and perform random coupling (private)
%
%   GET_SUBPATH_ANGLES generates the subpaths around the each path and
%   randomly couples the subpaths on the Tx- and Rx side. 
%
% QuaDRiGa Copyright (C) 2011-2016 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
% 
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published 
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

n_clusters  = h_builder(1,1).NumClusters;                     % no. clusters
n_subpath   = h_builder(1,1).NumSubPaths;
n_paths     = sum( h_builder(1,1).NumSubPaths );              % no. paths

if numel( h_builder(1,1).rx_track ) == 1
    i_track = 1;     % All MTs have the same Rx track
else
    i_track = i_mobile;
end

% The origianl 20 offset angles
% offset = [0.0447 0.1413 0.2492 0.3715 0.5129 0.6797 0.8844 1.1481 1.5195 2.1551];
% offset = [ offset , -offset ]*0.017453292519943;  % in rad

% The optimized order of the 20 sub-paths for 
offset = [-0.8844 1.1481 0.6797 -1.1481 -0.6797 1.5195 -0.0447 0.3715 -1.5195,...
    -0.2492 -0.5129 0.5129 0.8844 -2.1551 -0.1413 0.1413 0.0447 2.1551 -0.3715 0.2492 ];
%offset = offset * 0.017453292519943;  % in rad

% The per cluster angular spread scaling coefficients
c_aod = h_builder(1,1).scenpar.PerClusterAS_D;    % in deg
c_aoa = h_builder(1,1).scenpar.PerClusterAS_A;    % in deg
c_eod = h_builder(1,1).scenpar.PerClusterES_D;    % in deg
c_eoa = h_builder(1,1).scenpar.PerClusterES_A;    % in deg

% Reserve some memory for the output
aod = zeros( 1,n_paths );    
aoa = aod;
eod = aod;
eoa = aod;

subpath_coupling = h_builder(1,1).subpath_coupling(i_mobile,:,:);

ls = 1;
for l = 1 : n_clusters
    le = ls + n_subpath(l) - 1;
    
    % Get the subpath coupling
    cpl = qf.clst_extract( subpath_coupling, n_subpath, l  );
    
    % Get the offset angles
    if n_subpath(l) == 1
        of = 0;
    else
        of = offset( 1:n_subpath(l) );
        if n_subpath(l) < 20
            of = (of-mean(of));
            of = of./sqrt(mean(of.^2));
        end
        of = of .* 0.017453292519943;  % in rad
    end
    
    aod(ls:le) = c_aod * of( cpl(:,:,1) ) + h_builder(1,1).AoD( i_mobile,l );
    aoa(ls:le) = c_aoa * of( cpl(:,:,2) ) + h_builder(1,1).AoA( i_mobile,l );
    eod(ls:le) = c_eod * of( cpl(:,:,3) ) + h_builder(1,1).EoD( i_mobile,l );
    eoa(ls:le) = c_eoa * of( cpl(:,:,4) ) + h_builder(1,1).EoA( i_mobile,l );
    
    ls = le + 1;
end

% Calculate delays
if nargout == 5
    dl = h_builder(1,1).taus(i_mobile,:);
    n_snapshots = h_builder(1,1).rx_track(1,i_track).no_snapshots;
    if h_builder(1,1).simpar.use_absolute_delays
        r_0 = h_builder(1,1).rx_track(1,i_track).initial_position - h_builder(1,1).tx_position;
        D = sqrt(sum(r_0.^2)) / h_builder(1,1).simpar.speed_of_light;
        delay = repmat( dl+D , n_snapshots , 1  );
    else
        delay = repmat( dl , n_snapshots , 1  );
    end
end

end
