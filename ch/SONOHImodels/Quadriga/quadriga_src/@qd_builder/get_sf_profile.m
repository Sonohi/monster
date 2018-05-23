function [ sf,kf ] = get_sf_profile( h_builder, evaltrack )
%GET_SF_PROFILE Returns the shadow fading and the K-factor along a track 
%
% Calling object:
%   Single object
%
% Description:
%   This function returns the shadow fading and the K-factor along the given track. This function
%   is mainly used by the channel builder class to scale the output channel coefficients. The
%   profile is calculated by using the data in the LSF autocorrelation model and interpolating it
%   to the positions in the given track.
%
% Input:
%   evaltrack
%   Handle to a 'qd_track' object for which the SF and KF should be interpolated.
%
% Output:
%   sf
%   The shadow fading [linear scale] along the track
%
%   kf
%   The  K-factor [linear scale] along the track
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

% Parse input variable
if ~( isa(evaltrack, 'qd_track') )
    error('??? "evaltrack" must be of class "track".')
elseif ~any( size(evaltrack) == 1  )
    error('??? "evaltrack" must be vector.')
end

% Get the positions along the track
x = evaltrack.positions(1,:) + evaltrack.initial_position(1);
y = evaltrack.positions(2,:) + evaltrack.initial_position(2);
z = evaltrack.positions(3,:) + evaltrack.initial_position(3);

par = evaltrack.par;
if isempty( par ) || isempty(par.pg) || isempty(par.kf)
    % If there are no precalculated values for PG or KF get them from the SOS objects
    ksi = h_builder.get_lsp_val( [x;y;z] );
    
    % Format the output
    kf = permute( ksi(2,:,:) , [3,2,1] );
    sf = permute( ksi(3,:,:) , [3,2,1] );
end

% Read the SF and KF from the precalculated values in "evaltrack.par"
% Previously calculated values will be overwritten (e.g. when only partial
% initial LSPs are provided in "evaltrack.par".
if ~isempty( par )
    
    % By default, only one vector of SF or KF values can be given here.
    % If there are more than one in 'evaltrack.par', then it is likely
    % that they belong to different Txs. However, we have no way of
    % finding out, which Tx is meant here. This is sorted out in
    % 'layout.create_parameter_sets' instead. Hence, we only use the
    % first vector (or row) and throw a warning.
    if ~isempty(par.pg)
        sf = 10.^( 0.1*par.pg(1,:,:) );
        sf = permute( sf, [3,2,1] );
        
        if size( par.pg,1 ) > 1
            warning('QuaDRiGa:qd_builder:get_sf_profile',...
                ['Multiple path gain values found. ',...
                'There should be only one value per subtrack.']);
        end
    end
    if ~isempty(par.kf)
        kf =  10.^( 0.1*par.kf(1,:,:));
        kf = permute( kf, [3,2,1] );
        
        if size( par.kf,1 ) > 1
            warning('QuaDRiGa:qd_builder:get_sf_profile',...
                ['Multiple path gain values found. ',...
                'There should be only one value per subtrack.']);
        end
    end
end

end
