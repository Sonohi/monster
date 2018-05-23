function aso = gen_ssf_parameters( h_builder, init_all, vb_dots )
%GEN_SSF_PARAMETERS Generates the small-scale-fading parameters
%
% Calling object:
%   Single object
%
% Description:
%   This function creates the small-scale-fading parameters for the channel builder. Already
%   existing parameters are overwritten. However, due to the spatial consistency of the model,
%   identical values will be obtained for the same rx positions. Spatial consistency can be
%   disabled by setting qd_builder.scenpar.SC_lambda = 0
%
% Input:
%   init_all
%   By default, only the needed subset of the parameters is initialized. However, if you want to
%   change the model settings after creating the SSF parameters, you need to set init_all = 1
%
% Output:
%   aso
%   An array with angular spread values for each terminal in [deg]. The rows are [ AoD ; AoA ; EoD
%   ; EoA ]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if ~exist( 'init_all','var' ) || isempty( init_all )
    init_all = false;
end

verbose = h_builder(1,1).simpar.show_progress_bars;
if exist('vb_dots','var') && vb_dots == 0
    verbose = 0;
end

if verbose && nargin < 3
    fprintf('SSF Corr.    [');
    vb_dots = 50;
    tStart = clock;
end
m0=0;

if numel(h_builder) > 1
    
    % Equally distribute the dots in the progress bar
    sic = size( h_builder );
    vb_dots = zeros( 1,numel(h_builder) );
    for i_cb = 1 : numel(h_builder)
        [ i1,i2,i3,i4 ] = qf.qind2sub( sic, i_cb );
        if verbose
            vb_dots(i_cb) = h_builder(i1,i2,i3,i4).no_rx_positions;
        else
            % Workaround for Octave 4
            if numel( sic ) == 4
                h_builder(i1,i2,i3,i4).simpar.show_progress_bars = false;
            elseif numel( sic ) == 3
                h_builder(i1,i2,i3).simpar.show_progress_bars = false;
            else % 2 and 1
                h_builder(i1,i2).simpar.show_progress_bars = false;
            end
        end
    end
    if verbose
        vb_dots = qf.init_progress_dots(vb_dots);
    end
    
    for i_cb = 1 : numel(h_builder)
        [ i1,i2,i3,i4 ] = qf.qind2sub( sic, i_cb );
        if h_builder( i1,i2,i3,i4 ).no_rx_positions > 0
            gen_ssf_parameters( h_builder( i1,i2,i3,i4 ), init_all, vb_dots(i_cb) );
        end
    end
    
else
    % Fix for octave 4.0 (conversion from object-array to single object)
    h_builder = h_builder(1,1);
    
    % Delete existing data
    h_builder.taus = [];
    h_builder.pow = [];
    h_builder.AoD = [];
    h_builder.AoA = [];
    h_builder.EoD = [];
    h_builder.EoA = [];
    h_builder.xpr_path = [];
    h_builder.pin = [];
    h_builder.kappa = [];
    h_builder.random_pol = [];
    h_builder.gr_epsilon_r = [];
    h_builder.subpath_coupling = [];
    
    % Check if we need to update the large scale parameters
    if ~h_builder.data_valid
        h_builder.gen_lsf_parameters;
    end
    
    % Set the number of clusters
    n_clusters = h_builder.scenpar.NumClusters;
    
    % Get the number of frequencies
    n_freq = numel( h_builder.simpar.center_frequency );
    
    use_ground_reflection = logical( h_builder.scenpar.GR_enabled );
    if use_ground_reflection && n_clusters == 1
        error('You need at least 2 clusters to enable the ground reflection option.');
    end
    
    % Set the number of clusters
    h_builder.NumClusters = n_clusters;
    
    % Set the number of sub-paths per cluster
    if use_ground_reflection
        n_subpaths = [1,1,ones(1,n_clusters-2) * h_builder.scenpar.NumSubPaths];
    else
        n_subpaths = [1,ones(1,n_clusters-1) * h_builder.scenpar.NumSubPaths];
    end
    h_builder.NumSubPaths = n_subpaths;
    
    n_paths         = sum( n_subpaths );
    n_mobiles       = h_builder.no_rx_positions;
    
    % Spatial consistenc decorrelation distance in [m]
    SC_lambda = h_builder.scenpar.SC_lambda;
    
    % Ground Reflection Parameters
    generate_GR_parameters( h_builder );
    
    % Create input variables for the path generation function
    spreads = [ h_builder.ds; h_builder.asD; h_builder.asA;...
        h_builder.esD; h_builder.esA; h_builder.kf ];
    
    spreads = reshape( spreads , n_freq , 6 , [] );
    spreads = permute( spreads, [2,3,1] );
    
    if use_ground_reflection
        gr_epsilon_r = h_builder.gr_epsilon_r;
    else
        gr_epsilon_r = [];
    end
    
    [ pow, taus, AoD, AoA, EoD, EoA ] = generate_paths( h_builder.scenpar.NumClusters,...
        h_builder.tx_position, h_builder.rx_positions, spreads, SC_lambda, gr_epsilon_r );
    
    if h_builder.simpar.use_spherical_waves
        % This implements the multi-bounce model.
        % Those values are constant and need to be calculated only once
        oN = ones(1,n_mobiles);
        oL = ones(1,n_clusters);
        
        [ ahat_x, ahat_y, ahat_z ] = sph2cart( AoA, EoA, 1);
        ahat = permute( cat( 3, ahat_x, ahat_y, ahat_z ) , [3,1,2] );
        ahat = reshape( ahat , 3 , n_mobiles*n_clusters );
        
        [ bhat_x, bhat_y, bhat_z ] = sph2cart( AoD, EoD, 1);
        bhat = permute( cat( 3, bhat_x, bhat_y, bhat_z ) , [3,1,2] );
        bhat = reshape( bhat , 3 , n_mobiles*n_clusters );
        
        r = h_builder.rx_positions - h_builder.tx_position(:,oN);
        norm_r = sqrt(sum(r.^2)).';
        r = reshape( r(:,:,oL) , 3 , n_mobiles*n_clusters );
        
        dist = taus.*qd_simulation_parameters.speed_of_light + norm_r(:,oL);
        dist = permute( dist , [3,1,2] );
        dist = reshape( dist , 1 , n_mobiles*n_clusters );
        
        % Test if the optimization problem can be solved and update the angles
        % (single-bounce) that violate the assumptions.
        [ ~, ~, ~, valid ] = solve_multi_bounce_opti( ahat, bhat, r, dist, 2 );
        invalid = reshape( ~valid, n_mobiles,n_clusters ) ;
        invalid( :,1 ) = false;  % LOS is always valid
        
        if use_ground_reflection
            invalid( :,2 ) = false;  % Ground Reflection is always valid
        end
        
        % Use the single-bounce model for points where the problem has no
        % solution.
        if any( invalid(:) )
            [ b, norm_b ] = solve_cos_theorem( ahat(:,invalid(:)), r(:,invalid(:)), dist(invalid(:)) );
            AoD(invalid) = atan2(b(2,:,:),b(1,:,:) );
            EoD(invalid) = asin( b(3,:,:)./norm_b  );
        end
    end
    
    % Assign values to the builder
    h_builder.pow  = pow;
    h_builder.taus = taus;
    h_builder.AoD  = AoD;
    h_builder.AoA  = AoA;
    h_builder.EoD  = EoD;
    h_builder.EoA  = EoA;
    
    if nargout > 0
        N = size( h_builder.pow,1 );
        aso = zeros( 4,N,n_freq  );
        for iF = 1 : n_freq
            aso( 1,:,iF ) = qf.calc_angular_spreads( h_builder.AoD,  h_builder.pow(:,:,iF) )*180/pi;
            aso( 2,:,iF ) = qf.calc_angular_spreads( h_builder.AoA,  h_builder.pow(:,:,iF) )*180/pi;
            aso( 3,:,iF ) = qf.calc_angular_spreads( h_builder.EoD,  h_builder.pow(:,:,iF) )*180/pi;
            aso( 4,:,iF ) = qf.calc_angular_spreads( h_builder.EoA,  h_builder.pow(:,:,iF) )*180/pi;
        end
    end
    
    generate_initial_xpr( h_builder, init_all );
    
    % Update progress bar (50% point)
    if verbose; m1=ceil(1/2*vb_dots); if m1>m0;
            for m2=1:m1-m0; fprintf('o'); end; m0=m1; end;
    end;
    
    generate_subpaths( h_builder );             % Apply PerClusterDS and AS
    n_clusters = h_builder.NumClusters;         % Update Nclusters after splitting
    
    % Random initial phases
    % Phases are independent for each frequency in multi-frequency simulations
    pin = zeros( n_mobiles,n_paths,n_freq );
    if h_builder.simpar.use_random_initial_phase
        for iF = 1 : n_freq
            if SC_lambda == 0
                randC = rand( n_mobiles,n_paths );
            else
                randC = qd_sos.rand( ones(1,n_paths) * SC_lambda , h_builder.rx_positions ).';
            end
            pin(:,:,iF) = ( randC-0.5 )*2*pi;
        end
        
        % LOS path has zero-phase
        pin(:,1,:) = 0;
        
        if logical( h_builder.scenpar.GR_enabled )
            % Ground reflection has zero phase
            pin(:,2,:) = 0;
        end
    end
    h_builder.pin = pin;
    
    
    % Subpath coupling (spatial consistent)
    %     vals = max(h_builder.NumSubPaths) * n_clusters * 4;
    %     if SC_lambda == 0
    %         X = rand( n_mobiles , vals );
    %     else
    %         X = qd_sos.rand( ones(1,vals) * SC_lambda , h_builder.rx_positions ).';
    %     end
    %     X = reshape( X, n_mobiles, max(h_builder.NumSubPaths), n_clusters, 4 );
    %     X = permute( X, [2,3,1,4] );
    
    % Original value before spatial consistency extension
    % X = rand(max(h_builder.NumSubPaths),n_clusters,n_mobiles,4);
    
    % Same coupling for all users in the builder - maintains statial consistency
    % Different coupling for each frequency in multi-frequency simulations
    subpath_coupling = zeros( n_mobiles, n_paths, 4, n_freq, 'uint8' );
    for iF = 1 : n_freq
        X = rand( max(h_builder.NumSubPaths) , n_clusters , 1 , 4 );
        
        for l = 1 : n_clusters
            X( h_builder.NumSubPaths(l)+1:end,l,:,: ) = 1;
        end
        [~,X] = sort(X,1);
        %X = uint8( X );
        X = permute( X , [3,2,1,4] );
        
        Y = zeros( size(X,1), n_paths, 4, 'uint8' );
        for n = 1:4
            Y(:,:,n) = qf.clst_expand( X(:,:,:,n) , h_builder.NumSubPaths );
        end
        if size(Y,1) == 1 && n_mobiles > 1
            Y = Y( ones(1,n_mobiles), :, : );
        end
        
        subpath_coupling(:,:,:,iF) = Y;
    end
    h_builder.subpath_coupling = subpath_coupling;
    
    % Update progress bar( 100% point )
    if verbose; m1=ceil((2/2*vb_dots)); if m1>m0;
            for m2=1:m1-m0; fprintf('o'); end; m0=m1; end;
    end;
end

if verbose && nargin < 3
    fprintf('] %5.0f seconds\n',round( etime(clock, tStart) ));
end

end
