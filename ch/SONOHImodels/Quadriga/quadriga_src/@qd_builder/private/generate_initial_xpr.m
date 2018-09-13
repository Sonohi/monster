function generate_initial_xpr( h_builder, init_all )
%GENERATE_INITIAL_XPR Generates the initial XPR values

if numel( h_builder ) > 1
    error('QuaDRiGa:qd_builder:ObjectArray','??? "generate_initial_paths" is only defined for scalar objects.')
else
    h_builder = h_builder(1,1); % workaround for octave
end

L = h_builder.NumClusters;                      % no. taps
NumSubPaths = h_builder.NumSubPaths;
nF = numel( h_builder.simpar.center_frequency );

% Spatial consistenc decorrelation distance
SC_lambda = h_builder.scenpar.SC_lambda;

% Number of deterministic paths
if logical( h_builder.scenpar.GR_enabled )
    dL = 2;     % LOS + GR
else
    dL = 1;     % LOS only
end

% Total Number of NLOS Subpaths
M = sum( NumSubPaths( dL+1:end ) );

N = h_builder.no_rx_positions;                 % no. positions
oL = ones(1,L-dL);
oM = ones(1,M);

log10_f_GHz = log10( h_builder.simpar.center_frequency / 1e9 );

mu     = h_builder.scenpar.XPR_mu;
gamma  = h_builder.scenpar.XPR_gamma;
sigma  = h_builder.scenpar.XPR_sigma;
delta  = h_builder.scenpar.XPR_delta;

mu = mu + gamma * log10_f_GHz;
sigma = sigma + delta * log10_f_GHz;
sigma( sigma<0 ) = 0;

% Pre-assign variables
xpr_path = zeros( N, M+dL, nF );
if h_builder.simpar.use_geometric_polarization || init_all
    kappa = zeros( N, M+dL, nF );
else
    kappa = [];
end
if ~h_builder.simpar.use_geometric_polarization || init_all
    random_pol = zeros( N, M+dL, 4, nF );
else
    random_pol = [];
end


% XPR is indepentently genertated for different frequencies
for iF = 1 : nF
    
    % Linear Polarization
    
    % Generate spatially correlated random variables
    if SC_lambda == 0
        randC = randn( N,M );
    else
        randC = qd_sos.randn( ones(1,M) * SC_lambda , h_builder.rx_positions ).';
    end
    
    if h_builder.simpar.use_geometric_polarization
        % We get the mean value from the parameter set and add an additional
        % spread for the NLOS clusters. This spread is equal to the original
        % XPR-sigma.
        xpr_mu   = 10*log10( h_builder.xpr(iF,:).' );
        xpr_NLOS = randC * sigma(iF) + xpr_mu(:,oM);
        xpr_LOS  = Inf( N,dL );
        xpr_path(:,:,iF) = [ xpr_LOS , xpr_NLOS ];
        
    else
        % Use polarization model from WINNER / 3GPP
        xpr_NLOS = randC * sigma(iF) + mu(iF);
        xpr_LOS  = Inf( N,dL );
        xpr_path(:,:,iF) = [ xpr_LOS , xpr_NLOS ];
    end
    
    if h_builder.simpar.use_geometric_polarization || init_all
        % Circular Polarization
        % Generate spatially correlated random variables
        if SC_lambda == 0
            randC = randn( N,L-dL );
        else
            randC = qd_sos.randn( ones(1,L-dL) * SC_lambda , h_builder.rx_positions ).';
        end
        
        % Set the XPR for the circular polarization
        xpr_mu     = 10*log10( h_builder.xpr(iF,:).' );
        xpr_NLOS   = randC * sigma(iF) + xpr_mu(:,oL);
        xpr_NLOS   = 10.^( 0.1*xpr_NLOS );
        
        % Generate spatially correlated random variables
        if SC_lambda == 0
            randC = randi(2,N,L-dL);
        else
            randC = qd_sos.randi( ones(1,L-dL) * SC_lambda , h_builder.rx_positions, 2 ).';
        end
        rand_sign  = 2*( randC - 1.5 );
        
        kappa_CLST = [ zeros( N,dL ), rand_sign.*acot( sqrt(xpr_NLOS) ) ];
        kappa(:,:,iF) = qf.clst_expand( kappa_CLST, NumSubPaths );
    end
    
    if ~h_builder.simpar.use_geometric_polarization || init_all
        % Random polarization phasors
        if SC_lambda == 0
            randC = rand( N, M+dL, 4 );
        else
            randC = qd_sos.rand( ones(1,4*(M+dL)) * SC_lambda , h_builder.rx_positions ).';
            randC = reshape( randC, N, M+dL, 4 );
        end
        random_pol(:,:,:,iF) = randC*2*pi - pi;
    end
    
end

h_builder.xpr_path = xpr_path;
h_builder.kappa = kappa;
h_builder.random_pol = random_pol;

end
