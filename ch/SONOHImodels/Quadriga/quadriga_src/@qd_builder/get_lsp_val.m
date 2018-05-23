function par = get_lsp_val( h_builder, pos )
%GET_LSP_VAL Calculates the spatially correlated values of LSPs
%
% Calling object:
%   Single object
%
% Input:
%   pos
%   The 3D positions of the receivers in [m]; size [ 3 x N ]
%
% Output:
%   par
%   The values of the LSP; matrix of size [ 8 x N ]. The firs dimension corresponds to:
%      * Delay spread [s]
%      * K-factor [linear]
%      * Shadow fading [linear]
%      * Azimuth of departure angle spread [rad]
%      * Azimuth of arrival angle spread [rad]
%      * Elevation of departure angle spread [rad]
%      * Elevation of arrival angle spread [rad]
%      * Cross-polarization ratio [linear]
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

if ~exist('pos','var') || isempty( pos )
    pos = h_builder.rx_positions;
end

% Number of positions
nP = size(pos,2);
oP = ones(1,nP,'uint8');

% Number of frequencies
nF = numel( h_builder.simpar.center_frequency );
oF = ones(1,nF,'uint8');

% Read the LSPs from the scenario table
lsp = h_builder.lsp_vals;

if isempty( h_builder.sos )
    % Initialize the SOS objects
    [ par, h_builder.sos ] = qd_sos.randn( lsp(:,3,1), pos );
else
    % Read the values from the exsting SOS objects
    par = zeros(8,nP);
    for n = 1 : 8
        par(n,:) = h_builder.sos(n).val( pos );
    end
end

% Generate cross-correllation matrix
R_sqrt = sqrtm( h_builder.lsp_xcorr );
par = R_sqrt * par;

% Don't scale ESD when it is distance-dependent
if h_builder.scenpar.ES_D_mu_A ~= 0
    lsp(6,1,:) = 0;  
end

% Apply mu and sigma from the parameter table for each frequency
par = par( :,:,oF );    % Duplicate for each frequency
for iF = 1:nF
    par(:,:,iF) = par(:,:,iF) .* lsp(:,oP*2,iF) + lsp(:,oP,iF);
end

% Apply distant-dependent ESD scaling
if h_builder.scenpar.ES_D_mu_A ~= 0
    x = (pos(1,:) - h_builder.tx_position(1)) ./ 1000;
    y = (pos(2,:) - h_builder.tx_position(2)) ./ 1000;
    d_2d_km = sqrt( x.^2 + y.^2 );
    
    esd_mu = h_builder.scenpar.ES_D_mu_A .* d_2d_km + h_builder.scenpar.ES_D_mu;
    esd_mu( esd_mu < h_builder.scenpar.ES_D_mu_min ) = h_builder.scenpar.ES_D_mu_min;
    par(6,:,:) = par(6,:,:) + esd_mu(1,:,oF);
end

% Transform to linear values
par( [1,4:7],:,: ) = 10.^( par( [1,4:7],:,: ) );
par( [2,3,8],:,: ) = 10.^( 0.1 * par( [2,3,8],:,: ) );

end
