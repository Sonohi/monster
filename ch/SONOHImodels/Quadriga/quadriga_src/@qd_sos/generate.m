function h_sos = generate( R, D, L, dim, uniform_smp, debug )
%GENERATE Generates SOS parameters from a given ACF
%
% This (static) method tries to approximate any given ACF by sinusoid coefficients. A sampled ACF is provided at the
% input. Then, the L sinusoid coefficients are iteratively determined until the best match is achieved. 
%
% Input:
%   R       The desired ACF (having values between 1 ind -1). The first value must be 1.
%   D       Vector of sample points for the ACF in [m]
%   L       Number of sinusoid coefficients used to approximate the ACF
%   dim     Number of dimensions (1, 2 or 3)
%   uniform_smp    If set to 1, sample points for 2 or more dimensions are spaced equally. If set to 0, 
%                  sample pints are chosen randomly. Default: 0 (random)
%   debug   If set to 1, an animation plot of the progress is shown. Default: 0 
%
% Output:
%   h_sos   A qd_sos object.
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if ~exist( 'R','var' ) || isempty( R )
    error('You must specify an ACF.');
end

if ~exist( 'L','var' ) || isempty( L )
    error('You must specify the number of coefficients.');
end

% Read the number of sample points
N = uint16( numel(R) );
L = single( L );

if ~exist( 'D','var' ) || isempty( D )
    D = 0:N-1;
elseif numel(D) ~= numel( R )
    error('D and R must be of the same size');
end

if ~exist( 'dim','var' ) || isempty( dim )
    dim = 1;
end

if ~exist( 'uniform_smp','var' ) || isempty( uniform_smp )
    uniform_smp = false;
end

if ~exist( 'debug','var' )
    debug = false;
end

% Generate random angles for the multidiensional fit
switch dim
    case 1
        theta = [];                     % Elevation
        phi = [];                       % Azimuth

    case 2
        theta = [];                     % Elevation
        if uniform_smp                  % Azimuth
            u = 2 * pi / L;             % Circle circumference
            phi = 0 : u : 2*pi;
            phi = angle(exp(1j*phi(1:L))).';
        else
            % Random sampling of the unit circle
            phi = 2*(rand(L,1)-0.5)*pi;
        end
        
    case 3
        if uniform_smp
            [ theta, phi ] = pack_sphere( L );
            L = numel( phi );
        else
            % Random sampling of the unit sphere
            theta = acos( 2*rand(L,1)-1 )-pi/2;
            phi = 2*pi*(rand(L,1)-0.5)*pi;
        end
        % x = cos(phi) .* cos(theta); y = sin(phi) .* cos(theta); z = sin(theta); plot3(x,y,z,'.')
end

% Transform input tensor into a matrix for easier processing
% Single precision provides sufficient numeric accuracy but reduces
% computing and memory requirements.
R = reshape( single(R) , N , 1 ).';
D = reshape( single(D) , N , 1 ).';

% Generate SOS object
h_sos = qd_sos([]);
h_sos.Pdist_decorr = single( D( find( R <= exp(-1) ,1 ) ) );
h_sos.dist = D;
h_sos.acf = R;

% Normalize entries in D
maxD = max(D);
Dnorm = D./maxD;
PG = 2*pi*1j*Dnorm;

% Placeholder variables
fr = zeros( L, 1, 'single' );

% Predefine the weights with unit power and random phase
al = 1 / single(L);

% Calculate the first sampling frequency
fr(1,1) = suosi_iteration_step( R, Dnorm, al );

phi = single( phi );
theta = single( theta );

% Initial search
for l = 2:L

    if dim == 1
        frR = fr(1:l-1);
    elseif dim == 2
        frR = fr(1:l-1) .* cos( phi(1:l-1) );
    elseif dim == 3
        frR = fr(1:l-1) .* cos( phi(1:l-1) ) .* cos( theta(1:l-1) );
    end
    Rh = sum( exp( frR * PG )/l,1 );
    RminusRh = R-Rh;
    
    fr(l) = suosi_iteration_step( RminusRh, Dnorm, al );
    
    if debug % Debug
        [~,dbg] = suosi_cost( R, Dnorm, fr(1:l), phi, theta );
        plot( R,'k','Linewidth',3 );
        hold on;
        plot( dbg.' );
        hold off;
        title([1,l,l]);
        drawnow
    end
    
end

cst = suosi_cost( R, Dnorm, fr, phi, theta );
cnt = Inf;
loop = 1;

% Refinement
while cnt > 0
    cnt = 0;
    loop = loop + 1;
    for l = 1 : L
        
        % Remove all detected frequencies except the one that is refined
        ls = true(1,L);
        ls(l) = false;
        
        if dim == 1
            frR = fr(ls);
        elseif dim == 2
            frR = fr(ls) .* cos( phi(ls) );
        elseif dim == 3
            frR = fr(ls) .* cos( phi(ls) ) .* cos( theta(ls) );
        end
        Rh = al .* sum( exp( frR * PG ),1 );
        RminusRh = R-Rh;
        
        % Update the frequency
        frN = fr;
        frN(l) =  suosi_iteration_step( RminusRh, Dnorm, al );
        
        % Check if the results matches better
        [ cstN, dbg ] = suosi_cost( R, Dnorm, frN, phi, theta );
        
        if cstN < cst
            % Update the list of frequencies
            cnt = cnt + 1;
            fr = frN;
            cst = cstN;
            
            if debug
                plot( R,'k','Linewidth',3 );
                hold on;
                plot( dbg.' );
                hold off;
                title([loop,cnt,l]);
                drawnow
            end
        end
    end
end

% Scale the frequencies to match the distances
fr = fr / maxD;

% Calculate the decorrelations distane
if dim == 2
    % Map to fx and fy
    tmp = fr .* exp( 1j*phi );
    fr = [ real(tmp), imag(tmp) ];
    
elseif dim == 3
    % Map to fx and fy and fz
    fxy = zeros( L,3,'single' );
    fxy(:,1) = fr .* cos(phi) .* cos(theta);
    fxy(:,2) = fr .* sin(phi) .* cos(theta);
    fxy(:,3) = fr .* sin(theta);

    %   dcorr = D( find( R < exp(-1) ,1 ) );
    %   rcx = al * sum(  cos( 2*pi * fxy(:,1) * dcorr ) , 1 );
    %   rcy = al * sum(  cos( 2*pi * fxy(:,2) * dcorr ) , 1 );
    %   rcz = al * sum(  cos( 2*pi * fxy(:,3) * dcorr ) , 1 );
    
    fr = fxy;
end

h_sos.sos_freq = fr;
h_sos.sos_amp = al;
h_sos.init;

end

