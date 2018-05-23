function c = interpolate( h_channel, dist, method )
%INTERPOLATE Interpolates the channel coefficients and delays.
%
% Calling object:
%   Single object
%
% Description:
%   The channel builder creates one snapshot for each position that is listed in the track object.
%   When the channel sampling theorem is not violated (i.e. the sample density is ≥ 2), then the
%   channel can be interpolated to any other position on the track. This can be used e.g. to
%   emulate arbitrary movements along the track. For more information see
%   'qd_track.movement_profile', 'qd_track.interpolate_movement', or the tutorial "Applying Varying
%   Speeds (Channel Interpolation)".
%
% Input:
%   dist
%   A vector containing distance values on the track. The distance is measured in [m] relative to
%   the beginning of the track.  Alternatively, "dist" can be given as a 3-D tensor with dimensions
%   [ Rx-Antenna , Tx-Antenna , Snapshot ].  In this case, interpolation os done for each antenna
%   element separately.
%
%   method
%   Selects the interpolation algorithm. The default is linear interpolation. Optional are:
%      * linear - Linear interpolation (optimized for speed)
%      * spline - Cubic spline interpolation of the channel coefficients and piecewise cubic
%        hermite polynomial interpolation for the delays
%
% Output:
%   c
%   A 'qd_channel' object containing the  interpolated coefficients and delays for each entry in
%   'dist'.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_channel ) > 1
    error('QuaDRiGa:qd_channel:fr','??? "interpolate" is only defined for scalar objects.')
else
    h_channel = h_channel(1,1); % workaround for octave
end

if nargin < 2
    error('??? wrong number of input arguments. You mus specify "dist".');
end

if exist( 'method' , 'var' )
    supported_methods = {'linear','spline'};
    if ~( ischar(method) && any( strcmp(method,supported_methods)) )
        str = 'Interpolation method type not found; supported are: ';
        no = numel(supported_methods);
        for n = 1:no
            str = [str,supported_methods{n}];
            if n<no
                str = [str,', '];
            end
        end
        error(str);
    end
else
    method = 'linear';
end

% Get the dimension of the channel tensor
nrx = h_channel.no_rxant;
ntx = h_channel.no_txant;
nsnap = h_channel.no_snap;
L = h_channel.no_path;
individual_delays = h_channel.individual_delays;

% Get the snapshot positions from the channel data
if isempty( h_channel.rx_position )
    error('??? channel has no positioning information.')
end

pos_snap = [0;cumsum(abs(diff( h_channel.rx_position(1,:) + 1j*h_channel.rx_position(2,:) )))'];
track_length = pos_snap(end);

% Parse the distance values
if ~( isnumeric(dist) &&...
        isreal(dist) &&...
        min(dist(:))>=0 && max(dist(:)) - track_length < 1e-8 )
    error('??? "dist" must me numeric and can not exceed track length');
elseif numel( size(dist) ) == 2 && any( size(dist) ) == 1
    interpolate_per_antenna = false;
elseif size(dist,1) == nrx && size(dist,2) == ntx
    interpolate_per_antenna = true;
else
    error('??? "dist" has wrong format');
end

if interpolate_per_antenna
    ndist = size( dist,3 );
else
    ndist = numel( dist );
end

switch method
    
    case 'linear'
        
        if interpolate_per_antenna
            ndist_full = numel(dist);
        else
            ndist_full = ndist;
        end
        
        % Get the variables for the linear interpolation
        [tmp,b] = sort( dist(:) );
        [~,a]   = sort( [pos_snap ; tmp] );
        ui      = 1:(nsnap + ndist_full);
        ui(a)   = ui;
        ui      = ui(nsnap+1:end) - (1:ndist_full);
        ui(b)   = ui;
        ui( ui==nsnap ) = nsnap-1;
        uin     = ui+1;
        u       = (dist(:)-pos_snap(ui))./( pos_snap(uin)-pos_snap(ui) );
        
        % Expand the array size
        if interpolate_per_antenna
            tmp = reshape( 1:nrx*ntx , nrx,ntx );
            
            ii  = reshape( ui, size(dist) );
            ii  = (ii-1) .* nrx*ntx;
            ii  = ii + tmp( :,:,ones(1,ndist) );
            ii  = ii(:);
            
            iin = reshape( uin, size(dist) );
            iin = (iin-1) .* nrx*ntx;
            iin = iin + tmp( :,:,ones(1,ndist) );
            iin = iin(:);
            
            v   = u(:,ones(1,L) );
            
            % Update the coefficients
            tmp = permute( h_channel.coeff ,[1 2 4 3] );
            tmp = reshape( tmp , nrx*ntx*nsnap , L );
            
            c1 = (1-v).*abs(tmp( ii,: ))   + v.*abs(tmp( iin,: ));
            c2 = angle( (1-v).*tmp( ii,: ) + v.*tmp( iin,: ) );
            
            tmp = reshape( c1.*exp(1j*c2) , nrx , ntx , ndist , L );
            coeff = permute( tmp , [1 2 4 3] );
            
        else  % No interpolation per antenna
            v = u.';
            v = v( ones( 1, nrx*ntx*L ),: );
            v = reshape( v , nrx,ntx,L,ndist );
            
            % Update the coefficients
            c1 = (1-v).*abs(h_channel.coeff(:,:,:,ui)) + v.*abs(h_channel.coeff(:,:,:,uin));
            c2 = angle( (1-v).*h_channel.coeff(:,:,:,ui) + v.*h_channel.coeff(:,:,:,uin) );
            coeff = c1.*exp(1j*c2);
        end
        
        % Interpolate the delays
        if interpolate_per_antenna
            if individual_delays
                tmp = permute( h_channel.delay ,[1 2 4 3] );
            else
                tmp = permute( h_channel.delay ,[3 4 2 1] );
                tmp = tmp( ones(1,nrx),ones(1,ntx),:,: );
            end
            
            tmp = reshape( tmp , nrx*ntx*nsnap , L );
            tmp = (1-v).*tmp( ii,: )   + v.*tmp( iin,: );
           
            if individual_delays
                tmp = reshape( tmp , nrx , ntx , ndist , L );
                delay = permute( tmp , [1 2 4 3] );
            else
                tmp = mean( reshape(tmp, nrx*ntx,ndist,L ) , 1 );
                delay = permute( tmp , [3 2 1] );
            end
        else
            if individual_delays
                delay = (1-v).*h_channel.delay(:,:,:,ui) + v.*h_channel.delay(:,:,:,uin);
            else
                v = u( :,ones( 1, L ) ).';
                delay = (1-v).*h_channel.delay(:,ui) + v.*h_channel.delay(:,uin);
            end
        end
              
        % Write data to a new channel object
        c = qd_channel( coeff, delay );
        c.name = h_channel.name;
        c.version = h_channel.version;
        c.individual_delays = h_channel.individual_delays;
        c.tx_position = h_channel.tx_position;
        
        % Interpolate rx positions (if provided)
        if ~isempty(h_channel.rx_position)
            rx_position = zeros( 3,ndist );
            if interpolate_per_antenna
                tmp = permute( h_channel.rx_position ,[3 4 2 1] );
                tmp = tmp( ones(1,nrx),ones(1,ntx),:,: );
                
                tmp = reshape( tmp , nrx*ntx*nsnap , 3 );
                tmp = (1-v(:,1:3)).*tmp( ii,: )   + v(:,1:3).*tmp( iin,: );
                tmp = mean( reshape( tmp , nrx*ntx , ndist , 3 ) );
                
                rx_position = permute( tmp , [3 2 1] );
            else
                for n=1:3
                    rx_position(n,:) = (1-u.').*h_channel.rx_position(n,ui) +...
                        u.'.*h_channel.rx_position(n,uin);
                end
            end
            c.rx_position = rx_position;
        end
        
    case 'spline'
        
        % Here, we use the MATLAB internal spline interpolation
        dd = dist( : ).';
        pos_snap = pos_snap.';
        
        if interpolate_per_antenna
            individual_delays = h_channel.individual_delays;
            if ~individual_delays
                h_channel.individual_delays = true;
            end
            coeff = zeros( nrx, ntx, L, ndist );
            delay = zeros( nrx, ntx, L, ndist );
            for r = 1 : nrx
                for t = 1 : ntx
                    dd = reshape( dist( r,t,: ) , 1, [] );
                    c0 = reshape( h_channel.coeff(r,t,:,:) , L, nsnap ) ;
                    c1 = spline( pos_snap , abs(c0)  , dd );
                    c2 = angle( spline( pos_snap , c0 , dd ) );
                    coeff(r,t,:,:) = c1.*exp(1j*c2);
                    
                    delay(r,t,:,:) = ...
                        pchip( pos_snap , reshape( h_channel.delay(r,t,:,:) ,L,nsnap ) , dd );
                end
            end
            dd = mean( reshape( dist , [] , ndist ) );
            if ~individual_delays
                h_channel.individual_delays = false;
            end
        else
            c0 = reshape( h_channel.coeff, [], nsnap );
            c1 = spline( pos_snap , abs(c0)  , dd );
            c2 = angle( spline( pos_snap , c0 , dd ) );
            coeff = reshape( c1.*exp(1j*c2), nrx,ntx,L, [] );
            
            if individual_delays
                d0 = reshape( h_channel.delay, [], nsnap );
                d0 = pchip( pos_snap , d0 , dd );
                delay = reshape( d0, nrx,ntx,L, [] );
            else
                delay = pchip( pos_snap , h_channel.delay , dd );
            end
        end
        
        c = qd_channel( coeff,delay );
        c.name = h_channel.name;
        c.version = h_channel.version;
        c.individual_delays = individual_delays;
        c.tx_position = h_channel.tx_position;
        
        % Interpolate rx positions (if provided)
        if ~isempty(h_channel.rx_position)
            c.rx_position = pchip( pos_snap , h_channel.rx_position , dd );
        end
        
    otherwise
        return
end

end

