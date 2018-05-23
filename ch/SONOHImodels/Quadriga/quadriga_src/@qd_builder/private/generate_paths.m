function [ pow, taus, AoD, AoA, EoD, EoA ] = generate_paths( L, tx_pos, rx_pos, spreads, SC_lambda, gr_epsilon_r )
%GENERATE_PATHS Generate multipath components
%
% Input:
%   L               Number of paths (including LOS and GR) [ 1 x 1 ]
%   tx_pos          Tx-position (metric) [ 3 x 1 ]
%   rx_pos          Rx-positions (metric) [ 3 x N ]
%   spreads         Vector of delay and angular spreads (see below) [ 6 x N x F ]
%   SC_lambda       Spatial consistency decorrelation distance in meters [ 1 x 1 ]; Default: 0 m (disabled)
%   gr_epsilon_r    Relative permeability for ground reflection [ N x F ]
%                   if set to empty [], ground reflection is disabled (default)
%
%   L = number of paths
%   N = number of users (from rx positions)
%   F = number of frequencies (from spreads)
%
% Content of variable spreads:
%   DS (s)
%   ASD (deg)
%   ASA (deg)
%   ESD (deg)
%   ESA (deg)
%   KF (linear)
%
% Output:
%   pow             Path powers (linear, normalized to sum 1) [ N x L x F ]
%   taus            Path delays (seconds) [ N x L ]
%   AoD             Azimuth angles of departure (rad) [ N x L ]
%   AoA             Azimuth angles of arrival (rad) [ N x L ]
%   EoD             Elevation angles of departure (rad) [ N x L ]
%   EoA             Elevation angles of arrival (rad) [ N x L ]

speed_of_light = qd_simulation_parameters.speed_of_light;

if ~exist('SC_lambda','var') || isempty( SC_lambda )
    SC_lambda = 0;
end

if ~exist('gr_epsilon_r','var') || isempty( gr_epsilon_r )
    gr_enabled = false;
else
    gr_enabled = true;
end

N = size( rx_pos, 2 );      % Number of users
F = size( spreads, 3 );     % Number of frequencies

oN = ones(1,N);
oF = ones(1,F);

% Get the number of deterministic and non-deterministic paths
if gr_enabled
    Lf = 2;
    Ln = L-2;
else
    Lf = 1;
    Ln = L-1;
end
oLn = ones(1,Ln);
oLf = ones(1,Lf);
oL = ones(1,L);

% Placeholder for the output variables
pow  = zeros( N, L, F );
taus = zeros( N, L );
AoD  = zeros( N, L );
AoA  = zeros( N, L );
EoD  = zeros( N, L );
EoA  = zeros( N, L );

% Read spread variables
spreadsP = permute( spreads , [2,3,1] );
DS  = spreadsP(:,:,1);
ASD = spreadsP(:,:,2) * pi/180;
ASA = spreadsP(:,:,3) * pi/180;
ESD = spreadsP(:,:,4) * pi/180;
ESA = spreadsP(:,:,5) * pi/180;
KF  = spreadsP(:,:,6);

% 2D distance between BS and MT
d_2d = sqrt( (tx_pos(1) - rx_pos(1,:)).^2 + (tx_pos(2) - rx_pos(2,:)).^2 );

% Calculate angles between BS and MT
angles = zeros( 5,N );
angles(1,:) = atan2( rx_pos(2,:) - tx_pos(2) , rx_pos(1,:) - tx_pos(1) );       % Azimuth at BS
angles(2,:) = pi + angles(1,:);                                                 % Azimuth at MT
angles(3,:) = atan( ( rx_pos(3,:) - tx_pos(3) ) ./ d_2d );                      % Elevation at BS
angles(4,:) = -angles(3,:);                                                     % Elevation at MT
angles(5,:) = -atan( ( rx_pos(3,:) + tx_pos(3) ) ./ d_2d );                     % Ground Reflection Elevation at BS and MT
angles = angles.';

if gr_enabled
    % LOS and GR path lengths
    d_3d = sqrt( sum((rx_pos - tx_pos(:,oN)).^2,1) );
    d_gf = sqrt( sum(([rx_pos(1:2,:);-rx_pos(3,:)] - tx_pos(:,oN)).^2,1) );
    
    % Incident angle of the GR
    theta_r = -angles(:,5);
    
    % Delay of the ground reflection relative to the LOS component
    tau_gr = ( d_gf-d_3d ).' / speed_of_light;
    
    % The reflection coefficient
    Z         = sqrt( gr_epsilon_r - (cos(theta_r)).^2 * oF );
    R_par     = (gr_epsilon_r .* (sin(theta_r)*oF) - Z) ./ (gr_epsilon_r .* (sin(theta_r)*oF) + Z);
    R_per     = ( sin(theta_r)*oF - Z) ./ ( sin(theta_r)*oF + Z);
    Rsq       = ( 0.5*(abs(R_par).^2 + abs(R_per).^2) );
end

if L == 1   % Only LOS component is present
    
    pow  = ones(N,1,F);
    taus = zeros(N,1);
    AoD  = angles(:,1);
    AoA  = angles(:,2);
    EoD  = angles(:,3);
    EoA  = angles(:,4);
    
elseif gr_enabled && L == 2   % Only LOS and GR componenet
    
    pow( :,1,: ) = (1-Rsq);
    pow( :,2,: ) = Rsq;
    taus = [ zeros(N,1), tau_gr ];
    AoD  = angles(:,1) * [1 1];
    AoA  = angles(:,2) * [1 1];
    EoD  = [ angles(:,3), angles(:,5) ];
    EoA  = [ angles(:,4), angles(:,5) ];
    
else % Additional NLOS componenets are present
    
    % The average initial values for all frequencies
    DSm  = 0.5 * min( DS,[],2 ) + 0.5 * max( DS,[],2 );
    ASDm = 0.5 * min( ASD,[],2 ) + 0.5 * max( ASD,[],2 );
    ASAm = 0.5 * min( ASA,[],2 ) + 0.5 * max( ASA,[],2 );
    ESDm = 0.5 * min( ESD,[],2 ) + 0.5 * max( ESD,[],2 );
    ESAm = 0.5 * min( ESA,[],2 ) + 0.5 * max( ESA,[],2 );
    
    % Generate random delays following an exponenetial distribution
    if SC_lambda == 0
        randC = rand( N,Ln );
    else
        randC = qd_sos.rand( oLn * SC_lambda , rx_pos ).';
    end
    taus(:,Lf+1:end) = -log( randC );
    
    % The DS of the unscales log-function is 1:
    % qf.calc_delay_spread( -log(randC(:).'), ones(1,numel(randC)))
    
    % Add ground reflection delay and calculate split the LOS power in a LOS and GR part
    if gr_enabled
        taus(:,2) = tau_gr;
        Pf = [ (1-mean(Rsq,2)) mean(Rsq,2) ];
    else % only LOS
        Pf = oN';
    end
    
    % Generate angles for the average angular spreads
    mu_fixed = zeros(N,4);  % The mean fixed angle
    path_angles = zeros( N,L,4 );
    for i_ang = 1 : 4
        
        % The LOS angle and the angle for the GR are deterministic and know from the BS and MT positions.
        % They are assembled before generating the NLOS angles. NLOS angles are distributed around the average fixed
        % angle.
        
        if gr_enabled
            if i_ang == 3 % EdD
                ang_fixed = [ angles(:,3) angles(:,5) ];
            elseif i_ang == 4 % EoA
                ang_fixed = [ angles(:,4) angles(:,5) ];
            else % AoD and AoA
                ang_fixed = angles(:,i_ang) * [1 1];
            end
        else % LOS only
            ang_fixed = angles( :,i_ang );
        end
        [ ~, mu_fixed(:,i_ang) ] = qf.calc_angular_spreads( ang_fixed, Pf, 0 );
        
        % Generate spatially correlated angles with zero-mean and unit variance
        if Ln == 1
            randC = ones(N,1) / sqrt(2);
        elseif Ln == 2
            randC = ones(N,1) * [-1 1] / sqrt(2);
        else % Ln > 2
            if SC_lambda == 0
                randC = rand( N,Ln );
            else
                randC = qd_sos.rand( oLn * SC_lambda , rx_pos ).';
            end
            % Limit angle range to [ -pi/2 , pi/2 ]
            randC = (randC - 0.5)*pi;
            
            % Normalize the random variables to zero mean and unit variance
            randC = randC - mean( randC,2 ) * oLn;
            tmp = 1 ./ std( randC,[],2);
            randC = randC .* (tmp * oLn);
        end
        
        path_angles(:,:,i_ang) = [ ang_fixed - mu_fixed(:,oLf*i_ang), randC ];
    end
    
    % Set the working point for the angular spread correction
    % Higer values allow a larger maximum AS
    % Lower value aloow better adjustment of the AS for different frequencies.
    % Values must be between 30 and 50 degrees.
    if F == 1
        WPa = 50;  % degree
        WPd = 0.7; % RMS-DS
    else
        WPa = 40;
        WPd = 0.4; % RMS-DS
    end
    
    % Generate path powers for the individual spreads
    for i_freq = 1 : F
        if gr_enabled
            Pf = [ 1-Rsq(:,i_freq), Rsq(:,i_freq) ];
        else
            Pf = oN';
        end
        Pf = Pf .* ((KF(:,i_freq) ./ ( 1 + KF(:,i_freq) ))*oLf);
        Pn = 1-sum(Pf,2);
        
        % Power for the delays
        sc = scale_delay( DSm, DS(:,i_freq), WPd );
        pDS = exp( -taus .* sc(:,oL) );

        % Power for the AoD
        sc = scale_angle( ASDm, ASD(:,i_freq), WPa );
        pASD = exp( -abs(path_angles(:,:,1)) .* sc(:,oL) );
        
        % Power for the AoA
        sc = scale_angle( ASAm, ASA(:,i_freq), WPa );
        pASA = exp( -abs(path_angles(:,:,2)) .* sc(:,oL) );
        
        % Power for the EoD
        sc = scale_angle( ESDm, ESD(:,i_freq), WPa );
        pESD = exp( -abs(path_angles(:,:,3)) .* sc(:,oL) );
        
        % Power for the EoA
        sc = scale_angle( ESAm, ESA(:,i_freq), WPa );
        pESA = exp( -abs(path_angles(:,:,4)) .* sc(:,oL) );
      
        % Combine values
        P = pDS .* pASD .* pASA .* pESD .* pESA;
        
        % Normalize and apply KF
        P(:,1:Lf) = 0;
        P = P .* (Pn ./ sum(P,2) * oL);
        P(:,1:Lf) = Pf;
        
        pow(:,:,i_freq) = P;
    end
    
    % Calculate the average powers for all frequencies
    if F > 1
        Pm = mean( pow,3 );
    else
        Pm = pow;
    end
    Pm = Pm ./ (sum( Pm,2 ) * oL);

    % Calculate the delay scaling factor (has analytic solution)
    if gr_enabled
        a = DSm.^2;
        b = Pm(:,2) .* tau_gr.^2;
        c = sum( Pm(:,3:end) .* taus(:,3:end).^2 , 2 );
        d = Pm(:,2) .* tau_gr;
        e = sum( Pm(:,3:end) .* taus(:,3:end) , 2 );
        S = ( sqrt( a.*c - a.*e.^2 - b.*c + b.*e.^2 + c.*d.^2 ) + d.*e ) ./ (c-e.^2);
    else
        a = DSm.^2;
        b = sum( Pm(:,2:end) .* taus(:,2:end) , 2 );
        c = sum( Pm(:,2:end) .* taus(:,2:end).^2 , 2 );
        S = sqrt( a ./ (c-b.^2) );
    end
    
    % Scale the delays
    taus(:,Lf+1:end) = taus(:,Lf+1:end) .* (S*oLn);
    
    % Scale the angles
    path_spreads = [ ASDm, ASAm, ESDm, ESAm ];
    for i_ang = 1 : 4
        
        % Surrent angular spread
        ang  = path_angles(:,:,i_ang);
        as   = qf.calc_angular_spreads( ang , Pm );
        
        % The following itertive optimization tries to find the optimal STD of the NLOS angles such that the given
        % angular spread is reached. If the given angular spread cannot be reached, the algorithm coverges to a maximum
        % value.
        
        % The cost function for the initial STD of 5.7 deg
        cst  = abs( 10*log10( as ./ path_spreads(:,i_ang) ) );
        
        step = ones( N,1 )*3;       % The initial logarithmic step-size (3 dB)
        ddir = ones( N,1 ) * -1;    % The initial search direction (increasing)
        upd  = true( N,1 );         % The values that need to be updated
        sigL = zeros( N,1 );        % Placeholder for the updated spreads
        sigN = sigL;                % Placeholder for the updated spreads
        cstN = cst;                 % Placeholder for the updated costs
        lp   = 1;                   % Loop counter
        
        while lp < 100 && any( upd )
            
            % Adjust the STD of the NLOS angles
            sigN(upd) = sigL(upd) + ddir(upd) .* step(upd);
            sig  = 10.^(0.1*( sigN(upd) ));
            
            % Update the angles and calculate the nw angular spread
            ang(upd, Lf+1:end) = sig*oLn .* path_angles(upd,Lf+1:end,i_ang);
            
            % Calculate angular spread
            as = qf.calc_angular_spreads( ang(upd,:), Pm(upd,:), 0 );
            
            % Update the cost function
            cstN(upd) = abs( 10*log10( as ./ path_spreads(upd,i_ang) ) );
            
            % If new costs are smaller, continue with step-size and direction
            ii   = cstN < cst;
            sigL(ii) = sigN(ii);
            cst(ii)  = cstN(ii);
            
            % If new costs are bigger, shange step-size and direction
            ddir(~ii) = -ddir(~ii);
            step(~ii) = 0.382 * step(~ii);
            
            % If target accuracy is reached, stop
            upd( cstN < 1e-4 ) = false;
            
            % Increase loop-counter
            lp = lp + 1;
        end
        
        % This would spread the angles several times around the unit circle
        sigN( sigN > 3.8 ) = 3.8;   % Max AS = 120 deg; 10*log10(120/50)
        sigN( sigN < -20 ) = -20;   % Min AS = 0.5 deg; 10*log10(0.5/50)
        
        % Calculate final angles
        sig  = 10.^(0.1*( sigN ));
        ang(:, Lf+1:end) = sig*oLn .* path_angles(:,Lf+1:end,i_ang);
        ang = ang + mu_fixed(:,oL*i_ang);
        
        % Wrap angles around the unit circle (does not change AS)
        ang  = mod( real(ang) + pi, 2*pi) - pi;
        
        % Restrict elevation range
        if i_ang > 2
            ang( ang >  pi/2 ) =  pi - ang( ang >  pi/2 );
            ang( ang < -pi/2 ) = -pi - ang( ang < -pi/2 );
        end
        
        switch i_ang
            case 1
                AoD = ang;
            case 2
                AoA = ang;
            case 3
                EoD = ang;
            case 4
                EoA = ang;
        end
    end
end

end
