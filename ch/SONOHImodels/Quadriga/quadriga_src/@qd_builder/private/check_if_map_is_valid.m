function valid = check_if_map_is_valid( scenpar_old , scenpar )
%CHECK_IF_MAP_IS_VALID Checks it the map is still valid after parameter change
%
% QuaDRiGa Copyright (C) 2011-2016 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
% 
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published 
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

names = fieldnames( scenpar_old );

% If any of the following parameters are changes, no new maps need to be generated. 
uncritical = {'NumClusters','NumClusters_gamma','NumSubPaths','r_DS',...
    'PerClusterAS_D','PerClusterAS_A','PerClusterES_D','PerClusterES_A','PerClusterDS',...
    'LNS_ksi','xpr_mu','xpr_sigma','xpr_gamma','xpr_delta','GR_enabled','GR_epsilon','SubpathMethod'};

O = struct2cell(scenpar_old);
N = struct2cell(scenpar);

critical = find( ~ismember(names,uncritical) );

valid = true; n=1;
while valid && n < numel( critical )
    if isinf(O{critical(n)}) || isinf(N{critical(n)}) || O{critical(n)} - N{critical(n)} ~= 0
        valid = false;
    end
    n=n+1;
end
