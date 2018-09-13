function [ phi_d_lm, theta_d_lm , lbs_pos , fbs_pos ] = calc_scatter_positions( h_builder, i_mobile )
%CALC_SCATTER_POSITIONS Calculates the positions of the scatterers
%
% Calling object:
%   Single object
%
% Description:
%   This function calculates the positions of the scatterers and initializes the drifting module.
%   The output variables are the NLOS Tx angles for the precomputation of the Tx array response.
%
% Input:
%   i_mobile
%   The index of the mobile terminal within the channel builder object
%
% Output:
%   phi_d_lm
%   The departure azimuth angles for each subpath
%
%   theta_d_lm
%   The departure elevation angles for each subpath
%
%   lbs_pos
%   The position of the last-bounce scatterer
%
%   fbs_pos
%   The position of the first-bounce scatterer
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

% Read some common variables
n_subpath           = h_builder.NumSubPaths;
n_path              = sum( n_subpath );
o_path              = ones( 1,n_path,'uint8' );

% The distance vector from the Tx to the initial position
r = h_builder.rx_positions(:,i_mobile) - h_builder.tx_position;
norm_r = sqrt(sum(r.^2)).';

% Get the total path length of the NLOS component
dist = qf.clst_expand( h_builder.taus(i_mobile, :), h_builder.NumSubPaths );  % Delay for each sub-path
dist = dist * qd_simulation_parameters.speed_of_light + norm_r;

% We get the initial angles with random coupling
[ phi_d_lm, theta_d_lm, phi_a_lm, theta_a_lm ] = get_subpath_angles( h_builder(1,1), i_mobile );

% Get the direction of the last bounce scatterer (LBS) seen from the
% receivers initial position.
[ ahat_lm_x, ahat_lm_y, ahat_lm_z ] = sph2cart(phi_a_lm, theta_a_lm, 1);
ahat_lm = [ ahat_lm_x; ahat_lm_y; ahat_lm_z ];

% Get the direction of the first bounce scatterer (FBS) seen from the
% transmitter center position.
[ bhat_lm_x, bhat_lm_y, bhat_lm_z ] = sph2cart(phi_d_lm, theta_d_lm, 1);
bhat_lm = [ bhat_lm_x; bhat_lm_y; bhat_lm_z ];

[ norm_a_lm, norm_b_lm,~,valid ] = solve_multi_bounce_opti( ahat_lm, bhat_lm, r, dist, 2 );

% LOS
norm_a_lm(1,1,:) = 0.5*norm_r;
norm_b_lm(1,1,:) = 0.5*norm_r;
valid(1,1,:) = true;

% For the invalid paths, use single-bounce-model
iv = ~valid;
if any( iv(:) )
    ahat_iv = [ ahat_lm_x(iv) ; ahat_lm_y(iv) ; ahat_lm_z(iv) ];
    
    [ b, norm_b_lm(iv), norm_a_lm(iv) ] = solve_cos_theorem( ahat_iv , r , dist(iv)  );
    
    tmp = norm_b_lm(iv);
    bhat_lm_x(iv) = b(1,:)./tmp;
    bhat_lm_y(iv) = b(2,:)./tmp;
    bhat_lm_z(iv) = b(3,:)./tmp;
end

% Calculate the FBS position (relative to initial Rx-pos)
fbs_pos = zeros( 3, n_path  );
fbs_pos(1,:) = norm_b_lm .* bhat_lm_x - r(1);
fbs_pos(2,:) = norm_b_lm .* bhat_lm_y - r(2);
fbs_pos(3,:) = norm_b_lm .* bhat_lm_z - r(3);

% Calculate the LBS position
lbs_pos = zeros( 3, n_path  );
lbs_pos(1,:) = norm_a_lm .* ahat_lm_x;
lbs_pos(2,:) = norm_a_lm .* ahat_lm_y;
lbs_pos(3,:) = norm_a_lm .* ahat_lm_z;

% Here, we calculate the vector pointing from each Tx element to the
% initial Rx position. This vector is stored in "e_tx" and update the
% departure angles.

e_tx       = h_builder.tx_array.element_position;
n_tx       = h_builder.tx_array.no_elements;
o_tx       = ones(1,n_tx);

r_t        = r(:,o_tx) - e_tx;
r_t        = permute( r_t,[1,3,4,2] );

b_tlm      = r_t(:,o_path,1,:) + fbs_pos(:,:,1,o_tx) ;
norm_bc    = sqrt( sum( b_tlm.^2 , 1 ) );

phi_d_lm   = atan2(b_tlm(2,:,:,:), b_tlm(1,:,:,:));
theta_d_lm = asin(b_tlm(3,:,:,:)./norm_bc);

norm_c_lm = sqrt(sum((lbs_pos - fbs_pos).^2));
norm_bc   = norm_bc + norm_c_lm( 1,:,1,o_tx );

% Initialize the drifting function
update_drifting( h_builder(1,1), 1, 1, i_mobile, lbs_pos, r_t, norm_bc, r );

% Calculate the scatterer positions in global coordinates.
% The positions are relative to the initial Rx-position. This is corrected
% here.
if nargout > 2
    rx_pos  = h_builder(1,1).rx_positions(:,i_mobile);
    lbs_pos = lbs_pos + rx_pos(:,o_path );
    fbs_pos = fbs_pos + rx_pos(:,o_path );
end

end
