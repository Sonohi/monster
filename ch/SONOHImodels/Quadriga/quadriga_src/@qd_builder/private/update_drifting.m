function [ phi_a_lms, theta_a_lms, psi_lms, tau_ls,...
    phi_d_1ms, theta_d_1ms, phi_a_1ms, theta_a_1ms, theta_r  ] =...
    update_drifting( h_builder, i_snapshot, init, varargin )
%UPDATE_DRIFTING Updates the drifting angles for the given snapshot
%
% This function provides new drifting angles, phases and delays for each
% snapshot specified by "snapshot". It is mandatory to call
% "calc_scatter_positions" first in order to initialize the drifting
% module.
%
% Output variables:
%   phi_a_lms       [ 1 , n_paths , n_rx ]
%       NLOS azimuth arrival angles
%
%   theta_a_lms     [ 1 , n_paths , n_rx ]
%       NLOS elevation arrival angles
%
%   psi_lms         [ 1 , n_paths , n_rx , n_tx ]
%       Phases
%
%   tau_ls          [ 1 , n_clusters , n_rx , n_tx ]
%       Delays
%
%   phi_d_1ms       [ 1 , 1/2 , n_rx , n_tx ]
%       LOS azimuth departure angles
%
%   theta_d_1ms     [ 1 , 1/2 , n_rx , n_tx ]
%       LOS elevation departure angles
%
%   phi_a_1ms       [ 1 , 1/2 , n_rx , n_tx ]
%       LOS azimuth arrival angles
%
%   theta_a_1ms     [ 1 , 1/2 , n_rx , n_tx ]
%       LOS elevation arrival angles
%
%   theta_r         [ n_rx , n_tx ]
%       Angle between the ground and the reflected path (ground reflection only)
%
% The four variables (phi_d_1ms, theta_d_1ms, phi_a_1ms, theta_a_1ms) have 2 elements if
% ground reflection is used and 1 element if only LOS is used.
%
% QuaDRiGa Copyright (C) 2011-2016 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

persistent i_mobile lbs_pos r_t norm_b_tlm r

if exist('init','var') && init
    i_mobile    = varargin{1};
    lbs_pos     = varargin{2};
    r_t         = varargin{3};
    norm_b_tlm  = varargin{4};
    r           = varargin{5};
    
else
    % Read some common variables
    n_paths             = size( lbs_pos , 2 );
    lambda              = h_builder(1,1).simpar.wavelength;
    o_path              = ones(1,n_paths);
    n_tx                = size( r_t, 4);
    
    if numel( h_builder(1,1).rx_array ) < i_mobile
        i_rx_array = 1;
    else
        i_rx_array = i_mobile;
    end
    if numel( h_builder(1,1).rx_track ) < i_mobile
        i_rx_track = 1;
    else
        i_rx_track = i_mobile;
    end
    
    n_rx = h_builder(1,1).rx_array(1,i_rx_array).no_elements;
    e_rx = h_builder(1,1).rx_array(1,i_rx_array).element_position;
    gdir = h_builder(1,1).rx_track(1,i_rx_track).ground_direction( i_snapshot );
    
    % Create index_lists
    % Again, this increases speed.
    o_rx = ones(1,n_rx);
    o_tx = ones(1,n_tx);
    
    % The vector from the initial position to the position at snapshot s
    e_s0 = h_builder(1,1).rx_track(1,i_rx_track).positions(:, i_snapshot ) ;
    
    % We rotate the Rx array around the z-axis so it matches the travel
    % direction of the MT. Then we calculate the vector from the initial
    % position to each element of the Rx-array at snapshot s.
    
    % Note, "gdir" is a vector containing the travel direction for each
    % snapshot on the track.
    
    % Temporal variables for the rotation
    c_gdir = cos(gdir);
    s_gdir = sin(gdir);
    e_rx_x = e_rx(1,:);
    e_rx_y = e_rx(2,:);
    
    % Apply the rotation
    e_s = zeros( 3,n_rx );
    e_s(1,:) = c_gdir.*e_rx_x - s_gdir.*e_rx_y;
    e_s(2,:) = s_gdir.*e_rx_x + c_gdir.*e_rx_y;
    e_s(3,:) = e_rx(3,:);
    
    % Add the positions of the rotated elements to the Rx position on the
    % track at snapshot s.
    e_s = e_s + e_s0(:,o_rx);
    e_s = reshape( e_s , 3 , 1 , n_rx );
    
    % NLOS Drifting:
    % Calculate the vector from the current Rx position to the LBS position
    a_rlms = lbs_pos(:,:,o_rx) - e_s( :,o_path,: );
    norm_a_rlms = sqrt( sum( a_rlms.^2 ,1 ) );
    
    % Update the arrival NLOS angles
    phi_a_lms   = atan2(a_rlms(2,:,:,:), a_rlms(1,:,:,:));
    theta_a_lms = asin(a_rlms(3,:,:,:)./norm_a_rlms);
    
    % The total path lengths for the NLOS components
    d_lms       = norm_a_rlms(1,:,:,o_tx) + norm_b_tlm(1,:,o_rx,:);
    
    % LOS Drifting:
    % The vector from the Tx to each Rx position.
    r_s         = r_t( :,1,o_rx,:) + e_s( :,1,:,o_tx );
    norm_r_s    = sqrt( sum( r_s.^2 ,1 ) );
    
    % Update the LOS angles
    phi_d_1ms   = atan2(r_s(2,:,:,:), r_s(1,:,:,:));
    theta_d_1ms = asin(r_s(3,:,:,:)./norm_r_s);
    phi_a_1ms   = atan2(-r_s(2,:,:,:), -r_s(1,:,:,:));
    theta_a_1ms = asin(-r_s(3,:,:,:)./norm_r_s);
    
    % For the LOS Rx angles, we use the first Tx array element
    phi_a_lms(1,1,:)   = phi_a_1ms(1,1,:,1);
    theta_a_lms(1,1,:) = theta_a_1ms(1,1,:,1);
    
    % The total path lengths for the LOS components
    d_lms(1,1,:,:) = norm_r_s(1,1,:,:);
    
    % Additional calculations for the ground reflection
    if logical( h_builder(1,1).scenpar.GR_enabled )
        % "r_t" points from Tx element to initial Rx position
        % "e_s" points from Initial Rx position to Rx element at current snapshot
        % We need to get the "mirror" position!
        
        % The vector pointing from the origin to the initial Rx position
        e_ri = h_builder(1,1).rx_positions(:,i_mobile);
        
        % The vector pointing from the origin to the current Rx element position
        e_rs = e_ri(:,1,o_rx) + e_s;
        
        % The vector pointing from the origin to the mirrored Rx element position
        e_rs(3,:) = -e_rs(3,:);
        
        % The vector pointing from the Tx element position to the mirrored Rx element position
        r_gr = -e_ri(:,1,o_rx,o_tx) + r_t(:,1,o_rx,:) + e_rs(:,1,:,o_tx);
        norm_r_gr    = sqrt( sum( r_gr.^2 ,1 ) );
        
        % Update the ground reflection angles
        phi_d_1ms(1,2,:,:)   = atan2(r_gr(2,:,:,:), r_gr(1,:,:,:));
        theta_d_1ms(1,2,:,:) = asin(r_gr(3,:,:,:)./norm_r_gr);
        phi_a_1ms(1,2,:,:)   = atan2(-r_gr(2,:,:,:), -r_gr(1,:,:,:));
        theta_a_1ms(1,2,:,:) = -asin(-r_gr(3,:,:,:)./norm_r_gr);
        
        % For the GR Rx angles, we use the first Tx array element
        phi_a_lms(1,2,:)   = phi_a_1ms(1,2,:,1);
        theta_a_lms(1,2,:) = theta_a_1ms(1,2,:,1);
        
        % The total path lengths for the GR components
        d_lms(1,2,:,:) = norm_r_gr(1,1,:,:);
        
        % Calculate the angle between the ground and the reflected path
        d_2d = sqrt( sum( r_gr([1,2],1,:,:).^2 ,1 ) );
        theta_r = atan( -r_gr(3,1,:,:) ./ d_2d );
        theta_r = permute( theta_r, [3,4,1,2] );
    else
        theta_r = [];
    end
    
    % The phases for each sub-path
    psi_lms     = 2*pi/lambda * mod(d_lms, lambda);
    
    % The average delay for each cluster
    tau_ls      = qf.clst_avg( d_lms, h_builder(1,1).NumSubPaths ) ./ h_builder(1,1).simpar.speed_of_light;
    
    % When we use relative delays, we have to normalize the delays to the LOS
    % tau_ls0 is the LOS delay at the RX-position without antennas. It is
    % needed when the coefficients are going to be normalized to LOS delay.
    if ~h_builder(1,1).simpar.use_absolute_delays
        norm_r_s0 = sqrt( sum( (r + e_s0).^2 ) );
        tau_ls0 = norm_r_s0 ./ h_builder(1,1).simpar.speed_of_light;
        tau_ls = tau_ls - tau_ls0;
    end
    
end

end
