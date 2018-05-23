function indoor_rx = set_scenario( h_layout, scenario, rx, tx, indoor_frc, SC_lambda )
%SET_SCENARIO Assigns scenarios to tracks and segments.
%
% Calling object:
%   Single object
%
% Description:
%   This function can be used to assign scenarios to tracks and segments of tracks. This takes the
%   distance-dependent LOS probability into account for some specific scenarios. Currently,
%   distance-dependent scenario selection is available for:
%      * 3GPP_3D_UMi
%      * 3GPP_3D_UMa
%      * 3GPP_38.901_UMi
%      * 3GPP_38.901_UMa
%      * 3GPP_38.901_RMa
%      * 3GPP_38.901_Indoor_Mixed_Office
%      * 3GPP_38.901_Indoor_Open_Office
%      * mmMAGIC_UMi
%      * mmMAGIC_Indoor
%
%    Alternatively, you can use all scenarios specified in 'qd_builder.supported_scenarios'.
%
% Input:
%   scenario
%   A string containing the scenario name
%
%   rx
%   A vector containing the receiver indices for which the scenarios should be set. Default: all
%   receivers
%
%   tx
%   A vector containing the transmitter indices for which the scenarios should be set. Default: all
%   transmitters.
%
%   indoor_frc
%   The fraction of the users (number between 0 and 1) that are indoors
%
% Output:
%   indoor_rx
%   A logical vector indicating if a user is indoors (1) or outdoors (0).
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_layout ) > 1
    error('QuaDRiGa:qd_layout:set_scenario','set_scenario not definded for object arrays.');
else
    h_layout = h_layout(1,1); % workaround for octave
end

no_rx = h_layout.no_rx;
no_tx = h_layout.no_tx;

if ~exist( 'scenario' , 'var' )
    scenario = [];
elseif iscell( scenario ) || ~ischar( scenario )
    error('Scenario must be a string.')
end

if ~exist( 'rx' , 'var' ) || isempty(rx)
    rx = 1 : no_rx;
end

if ~exist( 'tx' , 'var' ) || isempty(tx)
    tx = 1 : no_tx;
end

if ~exist( 'indoor_frc' , 'var' ) || isempty(indoor_frc)
    indoor_frc = 0;
end

if ~exist( 'SC_lambda' , 'var' ) || isempty(SC_lambda)
    SC_lambda = 0;
end

indoor_rx = [];

if any( strcmpi( scenario, qd_builder.supported_scenarios ))
    % Set single scenarios
    
    tmp = {scenario};                           % Convert to 1x1 cell array
    tmp = tmp( ones(h_layout.no_tx,1),1  );     % Expand for each Tx in the layout
    for i_rx = 1 : numel(rx)
        rx_ind = rx( i_rx );
        h_layout.track( 1, rx_ind ).scenario = tmp( :,ones(1,h_layout.track( 1, rx_ind ).no_segments) );
    end
    
else
    % Generate O2I penetration loss assuning that all users are indoor (38.901 only)
    switch scenario
        case { '3GPP_38.901_UMi', '3GPP_38.901_UMa' }
            h_layout.gen_o2i_loss( '3GPP_38.901', 0.5, SC_lambda, 25 );
        case { '3GPP_38.901_RMa' }
            h_layout.gen_o2i_loss( '3GPP_38.901', 1, SC_lambda, 10 );
        case { 'mmMAGIC_UMi' }
            h_layout.gen_o2i_loss( 'mmMAGIC', 0.5, SC_lambda, 25 );
    end
    
    % Determine if the user is indoor. If the MT is mobile, it stays indoors.
    if SC_lambda == 0
        tmp = rand( 1, numel(rx) );                                 % Random
    else
        tmp = qd_sos.rand( SC_lambda , h_layout.rx_position );  	% Spatially consistent
    end
    indoor_rx = tmp < indoor_frc;
    
    % If 38.901 MT is outdoor, remove indoor distance and indoor-loss
    switch scenario
        case { '3GPP_38.901_UMi', '3GPP_38.901_UMa', '3GPP_38.901_RMa', 'mmMAGIC_UMi'  }
            for i_rx = 1 : numel(rx)
                if indoor_rx( i_rx ) == 0
                    h_layout.track(1,i_rx).par = [];
                end
            end
        case { '3GPP_38.901_Indoor_Mixed_Office', '3GPP_38.901_Indoor_Open_Office', 'mmMAGIC_Indoor' }
            indoor_rx( : ) = 0;
    end
    
    % Get the MT positions, including segments on tracks
    rx_pos_2d = cell( 1,numel(rx) );
    rx_pos_3d = cell( 1,numel(rx) );
    no_rx_pos = 0;
    for i_rx = 1 : numel(rx)
        rx_ind = rx( i_rx );
        
        % Calculate the Tx-Rx distance for each segment on the track
        segment_index = h_layout.track( 1,rx_ind ).segment_index;
        oS = ones(1,numel(segment_index));
        no_rx_pos = no_rx_pos + numel(segment_index);
        
        rx_pos_2d{i_rx} = h_layout.track( 1, rx_ind ).positions( 1,segment_index ) +...
            h_layout.track( 1, rx_ind ).initial_position(1) +...
            1j*h_layout.track( 1, rx_ind ).positions( 2,segment_index ) + ...
            1j*h_layout.track( 1, rx_ind ).initial_position(2);
        
        rx_pos_3d{i_rx} = h_layout.track( 1, rx_ind ).positions( :,segment_index ) +...
            h_layout.track( 1,rx_ind ).initial_position * oS;
    end
    
    % Get the 2D Tx position (as complex number)
    tx_pos_2d = ( h_layout.tx_position( 1,: ) + 1j*h_layout.tx_position( 2,: ) ).';
    oT = ones( 1,no_tx );
    
    % Generate spatially consistent random variabels for the LOS / NLOS state
    if SC_lambda == 0
        randC = rand(no_tx,no_rx_pos);
    else
        randC = qd_sos.rand( ones(no_tx,1)*SC_lambda , h_layout.rx_position );
    end
    
    % Determine LOS probabilities and set the scenario accordingly
    rC = 1;                   % Index of the MT in randC
    for i_rx = 1 : numel(rx)
        rx_ind  = rx( i_rx );
        nS      = numel( rx_pos_2d{i_rx} );
        oS      = ones( 1,nS );
        randR   = randC(:,rC:rC+nS-1);
        rC      = rC+nS;
        dist_2d = abs( rx_pos_2d{i_rx}( oT,: ) - tx_pos_2d( :,oS ) );
        
        % Calculate the outdoor 2D distance (for indoor scenarios)
        if ~isempty( h_layout.track(1,i_rx).par )
            dist_3d_in = h_layout.track(1,i_rx).par.o2i_d3din;
            dist_3d = zeros( no_tx, nS );
            for iS = 1:nS
                dist_3d(:,nS) = sqrt( sum( abs( rx_pos_3d{i_rx}(:,iS) * oT - h_layout.tx_position ).^2,1 ) ).';
            end
            dist_2d_in = dist_2d .* dist_3d_in ./ dist_3d;
            dist_2d = dist_2d - dist_2d_in;
        end
        
        % Determine LOS probability
        switch scenario
            case '3GPP_3D_UMi'
                % See: 3GPP TR 36.873 V12.1.0 (2015-03)
                scen = { '3GPP_3D_UMi_LOS', '3GPP_3D_UMi_NLOS',...
                    '3GPP_3D_UMi_LOS_O2I', '3GPP_3D_UMi_NLOS_O2I' };
                
                % Determine the LOS probability for each BS-MT
                p_LOS = min( 18./dist_2d , 1 ) .* (1-exp(-dist_2d/36)) + exp(-dist_2d/36);
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_3D_UMa'
                % See: 3GPP TR 36.873 V12.1.0 (2015-03)
                scen = { '3GPP_3D_UMa_LOS', '3GPP_3D_UMa_NLOS',...
                    '3GPP_3D_UMa_LOS_O2I', '3GPP_3D_UMa_NLOS_O2I' };
                
                % Include height-dependency of the user terminals
                h_UT = h_layout.track( 1,rx_ind ).positions( 3,segment_index ) +...
                    h_layout.track( 1,rx_ind ).initial_position(3);
                
                C = zeros( size( dist_2d ));
                
                % Exclude outdoor users from height-dependency
                if indoor_rx(i_rx)
                    g = C;
                    
                    ii = dist_2d > 18;
                    g(ii) = 1.25e-6 .* dist_2d(ii).^2 .* exp( -dist_2d(ii)/150 );
                    
                    ii = h_UT > 13 & h_UT < 23;
                    if any(ii)
                        C( :,ii ) = ones(no_tx,1) * ((h_UT(ii)-13)/10).^1.5;
                    end
                    
                    C( :,h_UT >= 23 ) = 1;
                    C = C .* g;
                end
                
                % Determine the LOS probability for each BS-MT
                p_LOS = ( min( 18./dist_2d , 1 ) .* (1-exp(-dist_2d/63)) + exp(-dist_2d/63) )...
                    .* (1+C);
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_38.901_UMi'
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                
                % The corresponding scenario configuration files
                scen = { '3GPP_38.901_UMi_LOS', '3GPP_38.901_UMi_NLOS',...
                    '3GPP_38.901_UMi_LOS_O2I', '3GPP_38.901_UMi_NLOS_O2I' };
                
                % Determine the LOS probability for each BS-MT
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 18;
                p_LOS( ii )  = 18./dist_2d(ii) + exp(-dist_2d(ii)/36) .* (1 - 18./dist_2d(ii));
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_38.901_UMa' 
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                
                % The corresponding scenario configuration files
                scen = { '3GPP_38.901_UMa_LOS', '3GPP_38.901_UMa_NLOS',...
                    '3GPP_38.901_UMa_LOS_O2I', '3GPP_38.901_UMa_NLOS_O2I' };
                
                % Include height-dependency of the user terminals
                h_UT = h_layout.track( 1,rx_ind ).positions( 3,segment_index ) +...
                    h_layout.track( 1,rx_ind ).initial_position(3);
                
                C = zeros( size( dist_2d ));
                ii = h_UT > 13 & h_UT < 23;
                if any( ii )
                    C( :,ii ) = ones(no_tx,1) * ((h_UT(ii)-13)/10).^1.5;
                end
                C( :,h_UT >= 23 ) = 1;
                
                % Determine the LOS probability for each BS-MT
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 18;
                p_LOS( ii )  = ( 18./dist_2d(ii) + exp(-dist_2d(ii)/63) .* (1 - 18./dist_2d(ii)) ) .* ...
                    ( 1 + 5/4*C(ii) .* ( dist_2d(ii)./100 ).^3 .* exp(-dist_2d(ii)/150) );
                
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_38.901_RMa' 
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                
                % The corresponding scenario configuration files
                scen = { '3GPP_38.901_RMa_LOS', '3GPP_38.901_RMa_NLOS',...
                    '3GPP_38.901_RMa_LOS_O2I', '3GPP_38.901_RMa_NLOS_O2I' };
                
                % Determine the LOS probability for each BS-MT
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 10;
                p_LOS( ii )  = exp( -(dist_2d(ii)-10)/1000 );
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_38.901_Indoor_Mixed_Office'
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                scen = { '3GPP_38.901_Indoor_LOS', '3GPP_38.901_Indoor_NLOS' };
                
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 1.2 & dist_2d < 6.5;
                p_LOS( ii )  = exp( -(dist_2d(ii)-1.2)/4.7 );
                ii = dist_2d >= 6.5;
                p_LOS( ii )  = exp( -(dist_2d(ii)-6.5)/32.6 );
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case '3GPP_38.901_Indoor_Open_Office'
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                scen = { '3GPP_38.901_Indoor_LOS', '3GPP_38.901_Indoor_NLOS' };
                
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 5 & dist_2d <= 49;
                p_LOS( ii )  = exp( -(dist_2d(ii)-5)/70.8 );
                ii = dist_2d > 49;
                p_LOS( ii )  = exp( -(dist_2d(ii)-49)/211.7 );
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case 'mmMAGIC_UMi'
                % Same LOS probability model as in 3GPP is used
                % See: mmMAGIC Deliverable D2.2, Table 4.1
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                
                % The corresponding scenario configuration files
                scen = { 'mmMAGIC_UMi_LOS', 'mmMAGIC_UMi_NLOS',...
                    'mmMAGIC_UMi_LOS_O2I', 'mmMAGIC_UMi_NLOS_O2I' };
                
                % Determine the LOS probability for each BS-MT
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 18;
                p_LOS( ii )  = 18./dist_2d(ii) + exp(-dist_2d(ii)/36) .* (1 - 18./dist_2d(ii));
                
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            case 'mmMAGIC_Indoor'
                % Same LOS probability model as in 3GPP is used (mixed office)
                % See: mmMAGIC Deliverable D2.2, Table 4.1
                % See: 3GPP TR 38.901 V14.1.0 (2017-06) p27 Table 7.4.2-1
                
                % The corresponding scenario configuration files
                scen = { 'mmMAGIC_Indoor_LOS', 'mmMAGIC_Indoor_NLOS' };

                % Determine the LOS probability for each BS-MT
                p_LOS = ones( size( dist_2d ));
                ii = dist_2d > 1.2 & dist_2d < 6.5;
                p_LOS( ii )  = exp( -(dist_2d(ii)-1.2)/4.7 );
                ii = dist_2d >= 6.5;
                p_LOS( ii )  = exp( -(dist_2d(ii)-6.5)/32.6 );
                i_LOS = ( randR >= p_LOS ) + 1;
                
                
            otherwise
                error('QuaDRiGa:qf_builder:set_scenario:scenario_not_supported','Scenario is not supported.')
        end
        
        % Set the indoor scenarios
        if indoor_rx(i_rx)
            i_LOS = i_LOS + 2;
        end
        
        segment_index = h_layout.track( 1,rx_ind ).segment_index;
        tmp = size( h_layout.track( 1,rx_ind ).scenario );
        if tmp(1) == no_tx && tmp(2) == numel(segment_index)
            scen_old = h_layout.track( 1,rx_ind ).scenario;
            
        elseif tmp(1) == 1 && tmp(2) == 1
            scen_old = h_layout.track( 1,rx_ind ).scenario( ones(no_tx,numel(segment_index) ));
            
        elseif tmp(1) == no_tx && tmp(2) == 1
            scen_old = h_layout.track( 1,rx_ind ).scenario( :,ones(1,numel(segment_index) ));
            
        else
            error(['Scenario definition dimension mismatch for Rx ',num2str(rx_ind)]);
        end
        
        scen_current = reshape( scen( i_LOS(:) ) , no_tx,[] );
        
        % Assign scenario to track
        for i_txi = 1 : numel( tx )
            i_tx = tx( i_txi );
            scen_old( i_tx,: ) = scen_current( i_tx,: );
        end
        h_layout.track( 1,rx_ind ).scenario = scen_old;
    end
end
end
