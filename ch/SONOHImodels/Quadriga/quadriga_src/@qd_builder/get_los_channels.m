function h_channel = get_los_channels( h_builder, precision, return_coeff, tx_array_mask )
%GET_LOS_CHANNELS Generates channel coefficients for the LOS path only. 
%
% Calling object:
%   Object array
%
% Description:
%   This function generates static coefficients for the LOS path only. This includes the following
%   properties:
%      * antenna patterns
%      * orientation of the Rx (if provided)
%      * polarization rotation for the LOS path
%      * plane-wave approximation of the phase
%      * path loss
%      * shadow fading
%
%    No further features of QuaDRiGa are used (i.e. no drifting, spherical waves, time evolution,
%    multipath fading etc.). This function can thus be used to acquire quick previews of the
%    propagation conditions for a given layout.
%
% Input:
%   precision
%   The additional input parameter 'precision' can be used to set the numeric precision to
%   'single', thus reducing the memory requirements for certain computations. Default: double
%   precision.
%
%   return_coeff
%   Adjusts the format of the output. This is mainly used internally.
%   
%   return_coeff = 'coeff'; 
%   If this is set to 'coeff', only the raw channel coefficients are returned, but no QuaDRiGa
%   channel object is created. This may help to educe memory requirements. In this case, 'h_channel'
%   has the dimensions: [ n_rx, n_tx, n_pos ] 
%
%   return_coeff = 'raw'; 
%   Same as 'coeff' but without applying the distance-dependant phase and the path loss. The
%   rx-antenna is assumed to be dual-polarized with two elements (i.e. the rx interpolation is
%   omitted). This mode is used QuaDRiGa-internally by [qd_arrayant.combine_pattern]
%
%   tx_array_mask
%   Indices for selected transmit antenna elements
%
% Output:
%   h_channel
%   A 'qd_channel' object. The output contains one coefficient for each position in
%   'qd_builder.rx_position'.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

single_precision = true;
if ~exist('precision','var') || ~strcmp( precision , 'single' )
    precision = 'double';
    single_precision = false;
end

if exist('return_coeff','var') && ~isempty( return_coeff )
    switch return_coeff
        case 'coeff'
            return_coeff = true;
            raw_coeff = false;
        case 'raw'
            return_coeff = true;
            raw_coeff = true;
        otherwise
            return_coeff = false;
            raw_coeff = false;
    end
else
    return_coeff = false;
    raw_coeff = false;
end

if return_coeff && numel( h_builder ) ~= 1
    error('Raw channel coefficients can only be generted for scalar builder opjects.')
end

if ~exist( 'tx_array_mask','var' )
    tx_array_mask = [];
end

if numel( h_builder ) > 1
    
    sic = size( h_builder );
    h_channel = qd_channel;
    for i_cb = 1 : numel( h_builder )
        [ i1,i2,i3,i4 ] = qf.qind2sub( sic, i_cb );
        if h_builder( i1,i2,i3,i4 ).no_rx_positions > 0
            h_channel( i1,i2,i3,i4 ) = get_los_channels( h_builder( i1,i2,i3,i4 ), precision, [], tx_array_mask );
        end
    end
    
else
    % Fix for octave 4.0 (conversion from object-array to single object)
    h_builder = h_builder(1,1);
    
    % Check if we have a single-grequency builder
    if numel( h_builder.simpar.center_frequency ) > 1
         error('QuaDRiGa:qd_builder:get_los_channels','get_los_channels only works for single-freqeuncy simulations.');
    end
    
    if numel( h_builder.rx_array ) > 1 && any( ~qf.eqo( h_builder.rx_array(1,1) , h_builder.rx_array ) )
        error('QuaDRiGa:qf_builder:get_los_channels:Rx_array_ambiguous',...
            ['There is more than one Rx array antenna in "h_builder".\n ',...
            '"get_los_channels" can only use one array antenna. Results might be erroneous.']);
    end
    
    if numel( h_builder.simpar.center_frequency ) > 1 || numel( h_builder.tx_array  ) > 1
        error('QuaDRiGa:qf_builder:get_los_channels:Tx_array_ambiguous',...
            ['There is more than one Tx array antenna in "h_builder".\n ',...
            '"get_los_channels" can only use one array antenna. Results might be erroneous.']);
    end
    
    lambda  = h_builder.simpar.wavelength;
    n_positions = h_builder.no_rx_positions;
    wave_no = 2*pi/lambda;
    
    % Extract the travel directions at the initial position
    gdir = zeros(1,n_positions);
    if numel( h_builder.rx_track ) == n_positions
        for i_pos = 1 : n_positions
            if isempty( h_builder.rx_track(1,i_pos).ground_direction )
                h_builder.rx_track(1,i_pos).compute_directions;
            end
            [~,ind] = min( sum( h_builder.rx_track(1,i_pos).positions.^2 ) );
            gdir(i_pos) = h_builder.rx_track(1,i_pos).ground_direction( ind );
        end
    end
    
    % Get the arrival and departure angles
    angles = h_builder.get_angles*pi/180;
    if single_precision
        angles = single( angles );
    end
    
    % Interpolate the patterns
    if exist( 'tx_array_mask','var' ) && ~isempty( tx_array_mask )
        [ Vt,Ht,Pt ] = h_builder.tx_array(1,1).interpolate( angles(1,:) , angles(3,:), tx_array_mask );
        Ct = h_builder.tx_array(1,1).coupling( tx_array_mask,tx_array_mask );
        n_tx = numel(tx_array_mask);
    else
        [ Vt,Ht,Pt ] = h_builder.tx_array(1,1).interpolate( angles(1,:) , angles(3,:) );
        Ct = h_builder.tx_array(1,1).coupling;
        n_tx = h_builder.tx_array(1,1).no_elements;
    end
    
    if raw_coeff
        n_rx = 2;
        % It is possible to provide different Jones matrices for the raw coefficients
        if h_builder.rx_array(1,1).no_elements == 2
            Cr = h_builder.rx_array(1).coupling.';
        else
            Cr = eye(2);
        end
    else
        [ Vr,Hr,Pr ] = h_builder.rx_array(1,1).interpolate( angles(2,:)-gdir , angles(4,:) );
        n_rx = h_builder.rx_array(1,1).no_elements;
        Cr = h_builder.rx_array(1,1).coupling.';
    end
    
    % Calculate the distance-dependent phases
    if ~raw_coeff
        r = (h_builder.rx_positions(1,:) - h_builder.tx_position(1)).^2 + ...
            (h_builder.rx_positions(2,:) - h_builder.tx_position(2)).^2 + ...
            (h_builder.rx_positions(3,:) - h_builder.tx_position(3)).^2;
        phase = 2*pi/lambda * mod( sqrt(r), lambda);
        
        if single_precision
            phase = single( phase );
        end
    end
    
    if single_precision
        wave_no = single( wave_no );
    end
    
    % Calculate the channel coefficients including polarization
    c = zeros( n_rx*n_tx , n_positions, precision );
    for i_tx = 1 : n_tx
        
        % Tx Patterns
        PatTx = [ reshape( Vt(1,:,i_tx) , 1,n_positions ) ;...
            reshape( Ht(1,:,i_tx) , 1,n_positions ) ];
        
        if raw_coeff
            
            % First component
            ind = (i_tx-1)*2 + 1;
            c(ind,:) = PatTx(1,:) .* exp( -1j*(  wave_no*( Pt(1,:,i_tx)  )));
            
            % Second component
            ind = ind + 1;
            c(ind,:) = PatTx(2,:) .* exp( -1j*(  wave_no*( Pt(1,:,i_tx)  )));
            
        else
            for i_rx = 1 : n_rx
                ind = (i_tx-1)*n_rx + i_rx;
                
                % Rx Patterns
                PatRx = [ reshape( Vr(1,:,i_rx) , 1,n_positions ) ;...
                    reshape( Hr(1,:,i_rx) , 1,n_positions ) ];
                
                % Coefficients and antenna-dependent phase offset
                c(ind,:) = ( PatTx(1,:) .* PatRx(1,:) - PatTx(2,:) .* PatRx(2,:) ).* ...
                    exp( -1j*(  wave_no*( Pt(1,:,i_tx) + Pr(1,:,i_rx) ) + phase ));
                
            end
        end
    end
    
    % Apply path loss
    if ~raw_coeff
        [ path_loss , scale_sf ] = h_builder.get_pl;
        if isempty( h_builder.sf )
            rx_power = -path_loss;
        else
            rx_power = -path_loss + 10*log10( h_builder.sf ) .* scale_sf;
        end
        rx_power = sqrt( 10.^( 0.1 * rx_power ) );
        c = c.*rx_power( ones(1,n_tx*n_rx) , : );
    end
    
    % Apply antenna coupling
    c = reshape( c , n_rx , n_tx , n_positions );
    
    if single_precision
        Ct = single( Ct );
        Cr = single( Cr );
    end
    
    if all(size(Ct) == [ n_tx , n_tx ]) && ...
            all(all( abs( Ct - eye(n_tx)) < 1e-10 )) && ...
            all(size(Cr) == [ n_rx , n_rx ]) && ...
            all(all( abs( Cr - eye(n_rx)) < 1e-10 ))
        
        % Both coupling matrixes are identity matrices.
        coeff = c;
        
    elseif all(size(Ct) == [ n_tx , n_tx ]) && ...
            all(all( abs( Ct - diag(diag(Ct)) ) < 1e-10 )) && ...
            all(size(Cr) == [ n_rx , n_rx ]) && ...
            all(all( abs( Cr - eye(n_rx)) < 1e-10 ))
        
        % The tx has a diagonal matrix and the rx an identity matrix
        coeff = zeros( n_rx , n_tx , n_positions , precision  );
        for i_tx = 1 : n_tx
            coeff( :,i_tx,: ) = c(:,i_tx,:) .* Ct( i_tx,i_tx );
        end
        
        
    elseif all(size(Cr) == [ n_rx , n_rx ]) && ...
            all(all( abs(Cr - eye(n_rx)) < 1e-10 ))
        
        % Only the Rx is an identity matrix.
        coeff = zeros( n_rx , size(Ct,2) , n_positions , precision  );
        for i_tx_in = 1 : n_tx
            for i_tx_out = 1 : size(Ct,2)
                coeff( :,i_tx_out,: ) = coeff( :,i_tx_out,: ) +...
                    c(:,i_tx_in,:) .* Ct(i_tx_in,i_tx_out );
            end
        end
        
    elseif all(size(Ct) == [ n_tx , n_tx ]) && ...
            all(all( abs(Ct - eye(n_tx)) < 1e-10 ))
        
        % Only the Tx is an identity matrix.
        coeff = zeros( size(Cr,1) , n_tx , n_positions , precision );
        for n = 1:n_positions
            coeff(:,:,n) = Cr * c(:,:,n);
        end
        
    else
        % Both coupling matrixes are not identity matrices.
        coeff = zeros( size(Cr,1) , size(Ct,2) , n_positions , precision );
        for n = 1:n_positions
            coeff(:,:,n) = Cr * c(:,:,n) * Ct;
        end
        
    end
    
    if return_coeff
        h_channel = coeff;
    else
        % Create output channel object
        coeff = reshape(coeff,size(coeff,1), size(coeff,2),1,n_positions);
        h_channel = qd_channel( coeff , zeros(1,n_positions,precision) , 1  );
        h_channel.name = h_builder.name;
        h_channel.tx_position = h_builder.tx_position;
        h_channel.rx_position = h_builder.rx_positions;
    end
end

end