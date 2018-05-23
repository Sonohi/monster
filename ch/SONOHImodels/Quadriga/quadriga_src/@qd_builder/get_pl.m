function [ loss, scale_sf, loss_init, scale_sf_init ] = get_pl( h_builder, evaltrack, alt_plpar )
%GET_PL Implements various path-loss models
%
% Calling object:
%   Single object
%
% Description:
%   This function implements various path-loss model such as defined by 3GPP 36.873 or 38.901. The
%   parameters of the various models are given in the configuration files in the in the folder
%   'quadriga_src config'. When a builder object is initialized, the parameters appear in the
%   structure 'qd_builder.plpar'.
%
% Input:
%   evaltrack
%   A 'qd_track' object for which the PL should be calculated. If 'evaltrack' is not given, then
%   the path loss is calculated for each Rx position. Otherwise the path loss is calculated for the
%   positions provided in 'evaltrack'.
%
%   alt_plpar
%   An optional alternative plpar which is used instead of 'qd_builder.plpar'.
%
% Output:
%   pl
%   The path loss in [dB]
%
%   scale_sf
%   In some scenarios, the SF might change with increasing distance between Tx and Rx. Hence, the
%   shadow fading provided by the parameter map has to be changed accordingly. The second output
%   parameter "scale_sf" can be used for scaling the (logarithmic) SF value from the map.
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

% Get the number of frequencies
CenterFrequency = h_builder.simpar.center_frequency' / 1e9;    % in GHz
nF = numel( CenterFrequency );
oF = ones( nF,1 );

% Get the tx_position
txpos = h_builder.tx_position;

% Use the alternative plpar, if given
if exist( 'alt_plpar','var' ) && ~isempty(alt_plpar)
    par = alt_plpar;
else
    par = h_builder.plpar;
end

% Get the rx positions (either from evaltrack of from the builder)
if exist( 'evaltrack','var' ) && ~isempty(evaltrack)
    if ~( isa(evaltrack, 'qd_track') )
        error('??? "evaltrack" must be of class "track".')
    end
    
    % Calculate the rx-position for each snapshot on the evaltrack
    initial_position = evaltrack.initial_position;
    rxpos = evaltrack.positions;
    rxpos = rxpos + initial_position * ones(1,size(rxpos,2));
    
    % Add the initial position to the PL calculate as well
    rxpos = [ rxpos, initial_position ];
    
    % There migth be a O2I penetration loss and a Indoor distance
    trk_par = evaltrack.par;
    if isempty( trk_par ) || isempty( trk_par.o2i_loss )
        o2i_loss = zeros(nF,1);
        d_3d_in = 0;
    else
        if evaltrack.no_segments == 1
            o2i_loss  = trk_par.o2i_loss(:,1,:);
            d_3d_in = trk_par.o2i_d3din(:,1);
        elseif evaltrack.no_segments == 2
            o2i_loss = trk_par.o2i_loss(:,2,:);
            d_3d_in = trk_par.o2i_d3din(:,2);
        else
            error('QuaDRiGa:qd_builder:get_pl','Too many segments in the evaltrack');
        end
        if size( o2i_loss,1 ) ~= 1 || size( d_3d_in,1 ) ~= 1
            error('QuaDRiGa:qd_builder:get_pl','O2I-loss is defined for more than on BS.');
        end
        if size( o2i_loss,3 ) ~= nF
            error('QuaDRiGa:qd_builder:get_pl','O2I-loss must be given for each frequency.');
        end
        o2i_loss = permute( o2i_loss,[3,1,2] );
    end
    
    nP = size( rxpos,2 );
    oP = ones(1,nP);
    use_track = true;
else
    evaltrack = [];
    rxpos = h_builder.rx_positions;
    o2i_loss = zeros(nF,1);
    d_3d_in = 0;
    nP = size( rxpos, 2 );
    oP = ones(1,nP);
    use_track = false;
end

% Calculate the distance between Tx and Rx
d_3d = oF * sqrt( sum( (rxpos - txpos(:,oP)).^2 , 1 ) );

% Calculate the 2D distance
d_2d = oF * sqrt( sum( (rxpos([1,2],:) - txpos([1,2],oP)).^2 , 1 ) );

if 1
    % percentage of the 3D distance that is indoor
    p_indoor = d_3d_in ./ d_3d;
    
    % Subtract the 3D indoor distance from the 3D distance to get the 3D outdoor distance
    d_3d = d_3d - d_3d_in;
    
    % Scale the 2D distance to obtain the 2D outdoor distance
    d_2d = d_2d .* (1-p_indoor);
end

% Set a minimum distance of 0.1 m to avoid artifacts
d_3d( d_3d < 0.1 ) = 0.1;
d_2d( d_2d < 0.1 ) = 0.1;

% Initialize output variables
scenpar     = h_builder.scenpar;
loss        = 0 .* (oF * oP);
sf_sigma    = oF * oP * scenpar.SF_sigma + scenpar.SF_delta * log10( CenterFrequency ) * oP;

% This implements the path loss models
if isfield( par , 'model' )
    switch par.model
        
        case 'logdist'
            loss = par.A * log10(d_3d) + par.B + par.C * log10(CenterFrequency) * oP;
            if isfield( par , 'SF' )
                sf_sigma(:) = par.SF;
            end
            
        case 'logdist_simple'
            loss = par.A * log10(d_3d) + par.B;
            
        case 'constant'
            loss = par.A * oF * oP;
            
        case 'winner_los'
            % From WINNER+ D5.3 pp. 74
            
            hBS = txpos(3);
            hMS = rxpos(3,:);
            
            hBS( hBS < 1.5  ) = 1.5;
            hMS( hMS < 1.5  ) = 1.5;
            
            % Calculate the breakpoint
            G = par.B1 + par.C1*log10(CenterFrequency) + par.D1*log10(hBS) + par.E1*log10(mean(hMS));
            H = par.B2 + par.C2*log10(CenterFrequency) + par.D2*log10(hBS) + par.E2*log10(mean(hMS));
            bp = 10.^( (H-G)./( par.A1-par.A2 ) );
            bp = bp * oP;
            
            hMS = oF * hMS;
            
            ind = d_2d<=bp;
            if any( ind(:) )
                freq_dep = par.C1*log10(CenterFrequency)*oP;
                loss(ind) = par.A1*log10(d_2d(ind)) + par.B1 + freq_dep(ind)...
                    + par.D1*log10(hBS) + par.E1*log10(hMS(ind)) + par.F1*hMS(ind);
                sf_sigma(ind) = par.sig1;
            end
            
            ind = ~ind;
            if any( ind(:) )
                freq_dep = par.C1*log10(CenterFrequency)*oP;
                loss(ind) = par.A2*log10(d_2d(ind)) + par.B2 + freq_dep(ind)...
                    + par.D2*log10(hBS) + par.E2*log10(hMS(ind)) + par.F2*hMS(ind);
                sf_sigma(ind) = par.sig2;
            end
            
        case 'winner_nlos'
            % From WINNER+ D5.3 pp. 74
            
            hBS = txpos(3);
            hMS = rxpos(3,:);
            
            hBS( hBS < 1.5  ) = 1.5;
            hMS( hMS < 1.5  ) = 1.5;
            
            loss1 = ( par.A1 + par.Ah1 * log10( hBS ))*log10(d_2d) + par.B1 + ...
                par.C1*log10(CenterFrequency)*oP + ...
                par.D1*log10(hBS) + ...
                oF * par.E1*log10(hMS) + ...
                oF * par.F1*hMS;
            
            loss2 = ( par.A2 + par.Ah2 * log10( hBS ))*log10(d_2d) + par.B2 + ...
                par.C2*log10(CenterFrequency)*oP + ...
                par.D2*log10(hBS) + ...
                oF * par.E2*log10(hMS) + ...
                oF * par.F2*hMS;
            
            loss3 = ( par.A3 + par.Ah3 * log10( hBS ))*log10(d_2d) + par.B3 + ...
                par.C3*log10(CenterFrequency)*oP + ...
                par.D3*log10(hBS) + ...
                oF * par.E3*log10(hMS) + ...
                oF * par.F3*hMS;
            
            i1 = CenterFrequency < 1.5;
            i2 = CenterFrequency >= 1.5 & CenterFrequency < 2;
            i3 = CenterFrequency >= 2;
            
            loss = i1 * oP .* loss1 + i2 * oP .* loss2 + i3 * oP .* loss3;
            
        case 'winner_pathloss'
            % See WINNER II D1.1.2 V1.2 (2007-09) p43 Equation (4.23)
            % PL/[dB] = A log10(d/[m]) + B + C log10(fc/[GHz]/5) + X
            
            loss = par.A * log10(d_3d) + par.B +...
                par.C * log10(CenterFrequency/5)*oP + par.X;
            
            if isfield( par , 'SF' )
                sf_sigma(:) = par.SF;
            end
            
        case 'dual_slope'
            
            % Set defaults
            if ~isfield( par,'A1' );    par.A2 = par.A;         end;
            if ~isfield( par,'A2' );    par.A2 = par.A1;        end;
            if ~isfield( par,'C' );     par.C = 0;              end;
            if ~isfield( par,'D' );     par.D = 0;              end;
            if ~isfield( par,'hE' );    par.hE = 0;             end;
            
            hBS = txpos(3);             % BS height
            hBS(hBS < 0) = 0;
            
            hMS = rxpos(3,:);           % MS height
            hMS(hMS < 0) = 0;
            
            % Breakpoint Distance
            BP = par.E * (hBS - par.hE) * CenterFrequency * (hMS - par.hE);
            
            loss     = par.A1*log10( d_3d ) + par.B + par.C*log10( CenterFrequency )*oP + par.D*d_3d;
            loss_dBP = par.A1*log10(   BP ) + par.B + par.C*log10( CenterFrequency )*oP + par.D*BP;
            loss_2   = loss_dBP + par.A2*log10( d_3d ./ BP );
            
            loss( d_2d>BP ) = loss_2( d_2d>BP );
            
            if isfield( par,'sig1' )
                sf_sigma( d_2d<=BP ) = par.sig1;
            end
            if isfield( par,'sig2' )
                sf_sigma( d_2d>=BP ) = par.sig2;
            end
            
        case 'tripple_slope'
            
            hBS = txpos(3);
            hMS = rxpos(3,:);
            
            BP1 = par.E1 * (hBS - par.hE1) * CenterFrequency * (hMS - par.hE1);
            BP2 = par.E2 * (hBS - par.hE2) * CenterFrequency * (hMS - par.hE2);
            
            % Copy hMS for multiple frequencies
            hMS = oF * hMS;
            
            % First Slope
            ind = d_2d <= BP1;
            if any(ind(:)) % for users < break point
                frq_dep = par.C*log10(CenterFrequency) * oP;
                loss(ind) = par.A1*log10(d_3d(ind)) + ...
                    par.B + frq_dep( ind );
                if isfield( par,'sig1' )
                    sf_sigma(ind) = par.sig1;
                end
            end
            
            % Second Slope
            ind = d_2d > BP1 & d_2d <= BP2;
            if any(ind(:)) % for users in between break points
                frq_dep = par.C*log10(CenterFrequency) * oP;
                loss(ind) = par.A2*log10(d_3d(ind)) + ...
                    par.B + frq_dep( ind ) + ...
                    par.D1*log10(BP1(ind).^2 + (hBS - hMS(ind)).^2);
                if isfield( par,'sig2' )
                    sf_sigma(ind) = par.sig2;
                end
            end
            
            % Third Slope
            ind = d_2d > BP2;
            if any(ind(:)) % for users > break point 2
                frq_dep = par.C*log10(CenterFrequency) * oP;
                loss(ind) = par.A3*log10(d_3d(ind)) + ...
                    par.B + frq_dep( ind ) + ...
                    par.D1*log10(BP1(ind).^2 + (hBS - hMS(ind)).^2) + ...
                    par.D2*log10(BP2(ind).^2 + (hBS - hMS(ind)).^2);
                if isfield( par,'sig3' )
                    sf_sigma(ind) = par.sig3;
                end
            end
            
        case 'nlos'
            
            %	PLn =   A * log10( d3d )
            %		 +  B
            %		 +  C * log10( fc )
            %		 +  D * log10( hBS + Dx )
            %		 + D1 * log10( hBS ) / hBS
            %		 + D2 * log10( hBS ) / hBS^2
            %		 + D3 * hBS
            %		 +  E * log10( hUT )
            %		 + E1 * log10( hUT ) / hUT
            %		 + E2 * log10( hUT ) / hUT^2
            %        + E3 * hUT
            %		 +  F * log10( hBS ) * log10( d3d )
            %		 + G1 * log10^2( G2 * hUT )
            
            % Set defaults
            if ~isfield( par,'Cn' );    par.Cn = 0;             end;
            if ~isfield( par,'Dn' );    par.Dn = 0;             end;
            if ~isfield( par,'D1n' );   par.D1n = 0;            end;
            if ~isfield( par,'D2n' );   par.D2n = 0;            end;
            if ~isfield( par,'D3n' );   par.D3n = 0;            end;
            if ~isfield( par,'En' );    par.En = 0;             end;
            if ~isfield( par,'E1n' );   par.E1n = 0;            end;
            if ~isfield( par,'E2n' );   par.E2n = 0;            end;
            if ~isfield( par,'E3n' );   par.E3n = 0;            end;
            if ~isfield( par,'Fn' );    par.Fn = 0;             end;
            if ~isfield( par,'G1n' );   par.G1n = 0;            end;
            if ~isfield( par,'G2n' );   par.G2n = 1;            end;
            
            % Get values from dual-slope LOS model
            par.model = 'dual_slope';
            [ tmp1, ~, tmp2 ] = h_builder.get_pl( evaltrack, par );
            loss_1 = [ tmp1, tmp2 ];
            
            hBS = txpos(3);
            hMS = oF * rxpos(3,:);
            
            % NLOS model
            loss = par.An * log10(d_3d) + par.Bn + par.Cn * log10(CenterFrequency) * oP ...
                + par.Dn * log10(hBS) + par.D1n * log10(hBS)./hBS + par.D2n * log10(hBS)./hBS.^2 + par.D3n * hBS ...
                + par.En * log10(hMS) + par.E1n * log10(hMS)./hMS + par.E2n * log10(hMS)./hMS.^2 + par.E3n * hMS...
                + par.Fn * log10(hBS) * log10(d_3d) ...
                + par.G1n * ( log10( par.G2n * hMS ) ).^2;
            
            loss( loss_1>loss ) = loss_1( loss_1>loss );
            
            if isfield( par,'sig' )
                sf_sigma(:) = par.sig;
            end
            
        otherwise
            error('??? PL model not defined in qd_parameter_set.get_pl')
    end
end

% Add outdoor-to-indoor penetration loss
loss = loss + o2i_loss * oP;

% The SF cannot change within a segment (sudden power changes)
if use_track
    sf_sigma = mean(sf_sigma,2) * oP;
end

% The shadow fading might change with distance. Hence, if
% the value did change, we have to rescale the values from
% the map.
SF_sigma_scenpar = scenpar.SF_sigma + scenpar.SF_delta * CenterFrequency;
if any( sf_sigma(:) ~= 0 ) && all( SF_sigma_scenpar ~= 0 )
    scale_sf = sf_sigma ./ (SF_sigma_scenpar * oP);
else
    scale_sf = ones( size( sf_sigma ) );
end

% Return results for track positions and initial position separately
if use_track
    loss_init       = loss(:,end);
    scale_sf_init   = scale_sf(:,end);
    loss            = loss(:,1:end-1);
    scale_sf        = scale_sf(:,1:end-1);
else
    loss_init       = [];
    scale_sf_init   = [];
end

end
