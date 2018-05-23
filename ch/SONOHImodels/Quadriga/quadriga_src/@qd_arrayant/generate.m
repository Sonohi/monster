function [ h_qd_arrayant, par ] = generate( array_type, Ain, Bin, Cin, Din, Ein, Fin, Gin, Hin, Iin, Jin )
%GENERATE Generates predefined array antennas
%
% Calling object:
%   None (static method)
%
%
% Array types:
%   omni
%   An isotropic radiator with vertical polarization.
%
%   dipole
%   A short dipole radiating with vertical polarization.
%
%   half-wave-dipole
%   A half-wave dipole radiating with vertical polarization.
%
%   patch
%   A vertically polarized patch antenna with 90° opening in azimuth and elevation.
%
%   custom
%   An antenna with a custom gain in elevation and azimuth. The values A,B,C and D for the
%   parametric antenna are returned.
%      * Ain - 3dB beam width in azimuth direction
%      * Bin - 3dB beam width in elevation direction
%      * Cin - Isotropic gain (linear scale) at the back of the antenna
%
%
%   parametric
%   An antenna with the radiation pattern set to
%        Eθ = A·√(B+(1-B)·(cosθ)^C ·(-D·ϕ^2))
%
%   multi
%   A multi-element antenna with adjustable electric downtilt.
%      * Ain - Number of elements stacked in elevation direction
%      * Bin - Element spacing in [λ]
%      * Cin - Electric downtilt in [deg]
%      * Din - Individual element pattern "Fa" for the vertical polarization
%      * Ein - Individual element pattern "Fb" for the horizontal polarization
%
%
%   3gpp-macro
%   An antenna with a custom gain in elevation and azimuth. See. 3GPP TR 36.814 V9.0.0 (2010-03),
%   Table A.2.1.1-2, Page 59
%      * Ain - Half-Power in azimuth direction (default = 70 deg)
%      * Bin - Half-Power in elevation direction (default = 10 deg)
%      * Cin - Front-to back ratio (default = 25 dB)
%      * Din - Electrical downtilt (default = 15 deg)
%
%
%   3gpp-3d
%   The antenna model for the 3GPP-3D channel model (TR 36.873, v12.5.0, pp.17).
%      * Ain - Number of vertical elements (M)
%      * Bin - Number of horizontal elements (N)
%      * Cin - The center frequency in [Hz]
%      * Din - Polarization indicator
%      * K=1, vertical polarization only
%        * K=1, H/V polarized elements
%        * K=1, +/-45 degree polarized elements
%        * K=M, vertical polarization only
%        * K=M, H/V polarized elements
%        * K=M, +/-45 degree polarized elements
%      * Ein - The electric downtilt angle in [deg] for Din = 4,5,6
%      * Fin - Element spacing in [λ], Default: 0.5
%
%
%   3gpp-mmw
%   Antenna model for the 3GPP-mmWave channel model (TR 38.901, v14.1.0, pp.21). The parameters
%   "Ain" - "Fin" are identical to the above model for the "3gpp-3d" channel model. Additional
%   parameters are:
%      * Gin - Number of nested panels in a column (Mg)
%      * Hin - Number of nested panels in a row (Ng)
%      * Iin - Panel spacing in vertical direction (dg,V) in [λ], Default: 0.5 M
%      * Jin - Panel spacing in horizontal direction (dg,H) in [λ], Default: 0.5 N
%
%
%   xpol
%   Two elements with ideal isotropic patterns (vertical polarization). The second element is
%   slanted by 90°.
%
%   rhcp-dipole
%   Two crossed dipoles with one port. The signal on the second element (horizontal) is shifted by
%   -90° out of phase. The two elements thus create a RHCP signal.
%
%   lhcp-dipole
%   Two crossed dipoles with one port. The signal on the second element (horizontal) is shifted by
%   90° out of phase. The two elements thus create a LHCP signal.
%
%   lhcp-rhcp-dipole
%   Two crossed dipoles. For input port 1, the signal on the second element is shifted by +90° out
%   of phase. For input port 2, the the signal on the second element is shifted by -90° out of
%   phase. Port 1 thus transmits a LHCP signal and port 2 transmits a RHCP signal.
%
%   ula2
%   Uniform linear arrays composed of 2 omni-antennas (vertical polarization) with 10 cm element
%   distance.
%
%   ula4
%   Uniform linear arrays composed of 4 omni-antennas (vertical polarization) with 10 cm element
%   distance.
%
%   ula8
%   Uniform linear arrays composed of 8 omni-antennas (vertical polarization) with 10 cm element
%   distance.
%
% Input:
%   array_type
%   One of the above array types.
%
%   Ain - Jin
%   Additional parameters for the array antenna (see above).
%
% Output:
%   par
%   The parameters A, B, C, and D for the "parametric" antenna type.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

supported_types = qd_arrayant.supported_types;
if ~exist( 'array_type' , 'var' ) || isempty(array_type)
    array_type = 'omni';
elseif ~( ischar(array_type) && any( strcmpi(array_type,supported_types)) )
    str = ['Array type "',array_type,'" not found. Supported types are: '];
    no = numel(supported_types);
    for n = 1:no
        str = [str,supported_types{n}];
        if n<no
            str = [str,', '];
        end
    end
    error(str);
end
array_type = lower( array_type );

% Default return for par
par = [];

switch array_type
    
    case 'omni'
        
        h_qd_arrayant = qd_arrayant( [] );
        h_qd_arrayant.name              = 'omni';
        h_qd_arrayant.no_elements       = 1;
        h_qd_arrayant.elevation_grid    = (-90:90)*pi/180;
        h_qd_arrayant.azimuth_grid      = (-180:180)*pi/180;
        h_qd_arrayant.element_position  = zeros( 3,1 );
        h_qd_arrayant.Fa    = ones( 181,361);
        h_qd_arrayant.Fb    = zeros( 181,361);
        h_qd_arrayant.coupling          = 1;

    case {'short-dipole', 'dipole'}
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        
        [~, theta_grid] = meshgrid( h_qd_arrayant.azimuth_grid, h_qd_arrayant.elevation_grid );
        
        % Short dipole
        E_theta = cos( (1 - 1e-6) * theta_grid );
        E_phi = zeros(size(E_theta));
        
        P = E_theta.^2 + E_phi.^2;      % Calculate radiation power pattern
        P_max = max(max(P));            % Normalize by max value
        P = P ./ P_max;
        
        % Calculate the Gain
        gain_lin = sum(sum( cos(theta_grid) )) / sum(sum( P.*cos(theta_grid) ));
        
        % Normalize by Gain
        E_theta = E_theta .* sqrt(gain_lin./P_max);
        E_phi = E_phi .* sqrt(gain_lin./P_max);
        
        h_qd_arrayant.Fa = E_theta;
        h_qd_arrayant.Fb = E_phi;
        
    case 'half-wave-dipole'
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');

        [~, theta_grid] = meshgrid(h_qd_arrayant.azimuth_grid, h_qd_arrayant.elevation_grid);
        
        % Half-Wave dipole
        E_theta = cos( pi/2*sin((1 - 1e-6) * theta_grid )) ./ cos((1 - 1e-6) * theta_grid);
        E_theta( isnan(E_theta) ) = 0;
        E_phi = zeros(size(E_theta));
        
        P = E_theta.^2 + E_phi.^2;      % Calculate radiation power pattern
        P_max = max(max(P));            % Normalize by max value
        P = P ./ P_max;
        
        % Calculate the Gain
        gain_lin = sum(sum( cos(theta_grid) )) / sum(sum( P.*cos(theta_grid) ));
        
        % Normalize by Gain
        E_theta = E_theta .* sqrt(gain_lin./P_max);
        E_phi = E_phi .* sqrt(gain_lin./P_max);
        
        h_qd_arrayant.Fa = E_theta;
        h_qd_arrayant.Fb = E_phi;
        
    case 'custom'
        
        % Set input variables
        if ~exist('Ain','var') || isempty( Ain )
            phi_3dB = 120;
        else
            phi_3dB = Ain;
        end
        
        if ~exist('Bin','var') || isempty( Bin )
            theta_3dB = 120;
        else
            theta_3dB = Bin;
        end
        
        if ~exist('Cin','var') || isempty( Cin )
            rear_gain = 0.1;
        else
            rear_gain = Cin;
        end
        
        if ~( size(phi_3dB,1) == 1 && isnumeric(phi_3dB) && isreal(phi_3dB) &&...
                all(size(phi_3dB) == [1 1]) )
            error('Azimuth HPBW (phi_3dB) has invalid value.')
        end
        
        if ~( size(theta_3dB,1) == 1 && isnumeric(theta_3dB) && isreal(theta_3dB) &&...
                all(size(theta_3dB) == [1 1]) )
            error('Elevation HPBW (theta_3dB) has invalid value.')
        end
        
        if ~( size(rear_gain,1) == 1 && isnumeric(rear_gain) && isreal(rear_gain) && ...
                all(size(rear_gain) == [1 1]) )
            error('Front-to-back ratio (rear_gain) has invalid value.')
        end
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        
        par.A = 0;
        par.B = 0;
        par.C = 0;
        par.D = 0;
        
        % Calculate the azimuth response
        phi = h_qd_arrayant.azimuth_grid;
        ind = find(phi/pi*180 >= phi_3dB/2, 1);
        
        a   = 1;        % Initial angle
        dm  = 0.5;      % Step size
        x   = inf;
        delta = Inf;
        ddir = +1;
        lp = 1;
        while lp < 5000 && delta > 1e-7
            if lp > 1
                an = a + ddir * dm;
                delta = abs(a-an);
            else
                an = a;
            end
            
            C = rear_gain + (1 - rear_gain) * exp(-an * phi.^2);
            xn = abs(C(ind) - 0.5);
            
            if xn < x
                a = an;
                x = xn;
            else
                ddir = -ddir;
                dm = 0.382 * dm;
            end
            lp = lp + 1;
        end
        C = exp(-an * phi.^2);
        par.D = an;
        
        % Calculate the elevation response
        theta = h_qd_arrayant.elevation_grid;
        ind = find(theta/pi*180 >= theta_3dB/2, 1);
        
        a   = 1;        % Initial angle
        dm  = 0.5;      % Step size
        x   = inf;
        delta = Inf;
        ddir = +1;
        lp = 1;
        while lp < 5000 && delta > 1e-7
            if lp > 1;
                an = a + ddir * dm;
                delta = abs(a-an);
            else
                an = a;
            end
            
            D = cos(theta).^an;
            xn = abs(D(ind) - 0.5);
            
            if xn < x
                a = an;
                x = xn;
            else
                ddir = -ddir;
                dm = 0.382 * dm;
            end
            lp = lp + 1;
        end
        D = cos(theta).^an;
        par.C = an;
        
        par.B = rear_gain;
        
        P = zeros(181,361);
        for a = 1:181
            for b = 1:361
                P(a, b) = D(a) * C(b);
            end
        end
        P = rear_gain + (1-rear_gain)*P;
        
        E_theta =  sqrt(P);
        
        [~, theta_grid] = meshgrid(h_qd_arrayant.azimuth_grid, h_qd_arrayant.elevation_grid);
        
        P = E_theta.^2;         % Calculate radiation power pattern
        P_max = max(max(P));    % Normalize by max value
        P = P ./ P_max;
        
        % Calculate the Gain
        gain_lin = sum(sum( cos(theta_grid) )) / sum(sum( P.*cos(theta_grid) ));
        par.A = sqrt(gain_lin./P_max);
        
        E_theta = E_theta .* sqrt(gain_lin./P_max);
        
        h_qd_arrayant.Fa = E_theta;
        h_qd_arrayant.Fb = zeros(h_qd_arrayant.no_el, h_qd_arrayant.no_az);
        
    case 'patch'
        
         h_qd_arrayant = qd_arrayant.generate('custom',90,90,0);
        
    case '3gpp-macro'
        
        % Set input variables
        if ~exist('Ain','var') || isempty( Ain )
            phi_3dB = 70;
        else
            phi_3dB = Ain;
        end
        
        if ~exist('Bin','var') || isempty( Bin )
            theta_3dB = 10;
        else
            theta_3dB = Bin;
        end
        
        if ~exist('Cin','var') || isempty( Cin )
            rear_gain = 25;
        else
            rear_gain = Cin;
        end
        
        if ~exist('Din','var') || isempty( Din )
            electric_tilt = 15;
        else
            electric_tilt = Din;
        end
        
        if ~( size(phi_3dB,1) == 1 && isnumeric(phi_3dB) && isreal(phi_3dB) &&...
                all(size(phi_3dB) == [1 1]) )
            error('Azimuth HPBW (phi_3dB) has invalid value.')
        end
        
        if ~( size(theta_3dB,1) == 1 && isnumeric(theta_3dB) && isreal(theta_3dB) &&...
                all(size(theta_3dB) == [1 1]) )
            error('Elevation HPBW (theta_3dB) has invalid value.')
        end
        
        if ~( size(rear_gain,1) == 1 && isnumeric(theta_3dB) && isreal(rear_gain) && ...
                all(size(rear_gain) == [1 1]) && rear_gain>=0 )
            error('Front-to-back ratio (rear_gain) has invalid value.')
        end
        
        if ~( size(electric_tilt,1) == 1 && isnumeric(electric_tilt) && isreal(electric_tilt) &&...
                all(size(electric_tilt) == [1 1]) )
            error('Electric tilt has invalid value.')
        end
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        
        phi = h_qd_arrayant.azimuth_grid*180/pi;
        Ah  = -min( 12*(phi./phi_3dB).^2 , rear_gain );
        
        theta = h_qd_arrayant.elevation_grid.'*180/pi;
        Av  = -min( 12*((theta+electric_tilt)./theta_3dB).^2 , rear_gain-5 );
        
        A = -min( -Ah(ones(h_qd_arrayant.no_el,1),:) - Av(:,ones(h_qd_arrayant.no_az,1)) , rear_gain );
        
        h_qd_arrayant.Fa = sqrt( 10.^(0.1*A) );
        h_qd_arrayant.normalize_gain;
        
        
    case 'multi'
        
        % Set inputs
        if ~exist('Ain','var') || isempty( Ain )
            no_elements = 8;
        else
            no_elements = Ain;
        end
        
        s = qd_simulation_parameters;
        if ~exist('Bin','var') || isempty( Bin )
            spacing = 0.5 * s.wavelength;
        else
            spacing = Bin * s.wavelength;
        end
        
        if ~exist('Cin','var') || isempty( Cin )
            tilt = 0;
        else
            % Convert tilt to [rad]
            tilt = Cin * pi/180;  
        end
        
        if ~exist('Din','var') || isempty( Din )
            tmp = qd_arrayant.generate('patch');
            Fa = tmp.Fa;
        else
            Fa = Din;
        end
        no_el_in = size( Fa, 3);
        
        if ~exist('Ein','var') || isempty( Ein )
            Fb = zeros( 181, 361, no_el_in);
        else
            Fb = Ein;
        end
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        if no_el_in > 1
            h_qd_arrayant.copy_element( 1,2:no_el_in );
        end
        h_qd_arrayant.Fa = Fa;
        h_qd_arrayant.Fb = Fb;
        
        % Copy the basic elements
        for n = 2:no_el_in
            h_qd_arrayant.copy_element( n, (n-1)*no_elements+1 );
        end
        
        % Set the element spacing
        el_pos = (0:no_elements-1) * spacing;
        el_pos = el_pos - mean(el_pos);
        for n = 1:no_el_in
            ind = (n-1)*no_elements + (1:no_elements);
            h_qd_arrayant.copy_element( (n-1)*no_elements+1 , ind );
            h_qd_arrayant.element_position(3,ind) = el_pos;
        end
        
        % Set the coupling
        C = 2*pi*sin(tilt) * h_qd_arrayant.element_position(3,:) / s.wavelength;
        C = exp( 1j*C );
        C = reshape( C, no_elements , no_el_in );
        coupling = C * sqrt(1/no_elements);
        coupling_array = zeros( no_el_in*no_elements, no_el_in );
        for n = 1:no_el_in
            ind = (n-1)*no_elements + (1:no_elements);
            coupling_array(ind,n) = coupling(:,n);
        end
        par = C;
        h_qd_arrayant.coupling = coupling_array;
        
        % calculate the effective pattern
        h_qd_arrayant.combine_pattern( s.center_frequency );
    
        
    case '3gpp-3d'
        
        % Set inputs
        if ~exist('Ain','var') || isempty( Ain )
            M = 10;
        else
            M = Ain;
        end
        if ~exist('Bin','var') || isempty( Bin )
            N = 10;
        else
            N = Bin;
        end
        if ~exist('Cin','var') || isempty( Cin )
            center_freq = 299792458;
        else
            center_freq = Cin;
        end
        if ~exist('Din','var') || isempty( Din )
            pol = 1;
        else
            pol = Din;
        end
        if ~exist('Ein','var') || isempty( Ein )
            tilt = 0;
        else
            tilt = Ein;
        end
        if ~exist('Fin','var') || isempty( Fin )
            spacing = 0.5;
        else
            spacing = Fin;
        end
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        
        % Antenna element vertical radiation pattern (dB)
        theta = h_qd_arrayant.elevation_grid.'*180/pi;
        Av  = -min( 12*(theta./65).^2 , 30 );
        
        % Antenna element horizontal radiation pattern (dB)
        phi = h_qd_arrayant.azimuth_grid*180/pi;
        Ah  = -min( 12*(phi./65).^2 , 30 );
        
        % Combining method for 3D antenna element pattern (dB)
        A = -min( -Av(:,ones(h_qd_arrayant.no_az,1)) -Ah(ones(h_qd_arrayant.no_el,1),:)  , 30 );
        
        % Set pattern
        h_qd_arrayant.Fa = sqrt( 10.^(0.1*A) );
        
        % Maximum directional gain of an antenna element is 8 dB
        h_qd_arrayant.normalize_gain(1,8);
        
        % Polarization
        switch pol
            case {2,5} % H / V polarization (0, 90 deg slant)
                h_qd_arrayant.copy_element(1,2);
                h_qd_arrayant.rotate_pattern(90,'x',2,2);
                
            case {3,6} % +/- 45 deg polarization
                h_qd_arrayant.copy_element(1,2);
                h_qd_arrayant.rotate_pattern(45,'x',1,2);
                h_qd_arrayant.rotate_pattern(-45,'x',2,2);
        end
        
        % Coupling of vertically stacked elements
        if pol >= 4
            h_qd_arrayant = qd_arrayant.generate('multi', M, spacing, tilt, h_qd_arrayant.Fa, h_qd_arrayant.Fb );
            M = 1;
        end
        
        if N > 1 || M > 1
            % Calculate the wavelength
            s = qd_simulation_parameters;
            s.center_frequency = center_freq;
            lambda = s.wavelength;
            
            % Copy elements
            T = h_qd_arrayant.no_elements;
            h_qd_arrayant.no_elements = T*N*M;
            for t=2:T
                ii = T+t : T : T*N*M;
                ij = ones(1,numel(ii))*t;
                h_qd_arrayant.Fa(:,:,ii) = h_qd_arrayant.Fa(:,:,ij);
                h_qd_arrayant.Fb(:,:,ii) = h_qd_arrayant.Fb(:,:,ij);
            end
            
            % Set vertical positions
            tmp = (0:M-1) * lambda*spacing;
            posv = tmp - mean(tmp);
            tmp = reshape( posv(ones(1,N),:).' , 1 , [] );
            h_qd_arrayant.element_position(3,:) =...
                reshape( tmp(ones(T,1),:) ,1,[] );
            
            % Set horizontal positions
            tmp = (0:N-1) * lambda*spacing;
            posh = tmp - mean(tmp);
            tmp = reshape( posh(ones(1,M),:) , 1 , [] );
            h_qd_arrayant.element_position(2,:) =...
                reshape( tmp(ones(T,1),:) ,1,[] );
        end
        
    case '3gpp-mmw'
        
        % Set inputs
        if ~exist('Ain','var') || isempty( Ain )
            Ain = 10;
        end
        if ~exist('Bin','var') || isempty( Bin )
            Bin = 10;
        end
        if ~exist('Cin','var') || isempty( Cin )
            Cin = 299792458;
        end
        if ~exist('Din','var') || isempty( Din )
            Din = 1;
        end
        if ~exist('Ein','var') || isempty( Ein )
            Ein = 0;
        end
        if ~exist('Fin','var') || isempty( Fin )
            Fin = 0.5;
        end
        if ~exist('Gin','var') || isempty( Gin )
            Gin = 2;
        end
        if ~exist('Hin','var') || isempty( Hin )
            Hin = 2;
        end
        if ~exist('Iin','var') || isempty( Iin )
            Iin = 0.5 * Ain;
        end
        if ~exist('Jin','var') || isempty( Jin )
            Jin = 0.5 * Bin;
        end
        
        % Generate single 3GPP panel
        h_qd_arrayant = qd_arrayant.generate('3gpp-3d',Ain,Bin,Cin,Din,Ein,Fin );
        
        if Gin > 1 || Hin > 1
            % Calculate the wavelength
            s = qd_simulation_parameters;
            s.center_frequency = Cin;
            lambda = s.wavelength;
            
            % Copy the array antenna
            hs = h_qd_arrayant.copy;
            
            % Nested panels in a column
            element_position = hs.element_position;
            tmp = element_position(3,:);
            for iR = 2 : Gin
                spc = (iR-1)*Iin*lambda;
                element_position(3,:) = tmp + spc;
                hs.element_position = element_position;
                h_qd_arrayant.append_array( hs );
            end
            
            if Hin > 1
                hs = h_qd_arrayant.copy;
            end
            
            % Nested panels in a row
            element_position = hs.element_position;
            tmp = element_position(2,:);
            for iC = 2 : Hin
                spc = (iC-1)*Jin*lambda;
                element_position(2,:) = tmp + spc;
                hs.element_position = element_position;
                h_qd_arrayant.append_array( hs );
            end
            
            % Center the element positions
            tmp = mean( h_qd_arrayant.element_position,2 );
            h_qd_arrayant.element_position = h_qd_arrayant.element_position - tmp(:,ones( 1,h_qd_arrayant.no_elements ));
        end
        
    case 'parametric'
        
        % Set inputs if not given
        if ~exist('Ain','var')
            Ain = 1.9;
        end
        if ~exist('Bin','var')
            Bin = 0.1;
        end
        if ~exist('Cin','var')
            Cin = 1;
        end
        if ~exist('Din','var')
            Din = 1.3;
        end
        
        % Generate omni antenna as default
        h_qd_arrayant = qd_arrayant.generate('omni');
        
        phi = h_qd_arrayant.azimuth_grid;
        theta = h_qd_arrayant.elevation_grid;
        
        C = cos(theta).^Cin;
        D = exp(-Din * phi.^2);
        
        P = zeros(numel( theta ),numel(phi));
        for a = 1:numel( theta )
            for b = 1:numel(phi)
                P(a, b) = C(a) * D(b);
            end
        end
        P = Bin + (1-Bin)*P;
        
        h_qd_arrayant.Fa = Ain * sqrt(P);
        h_qd_arrayant.Fb = zeros(h_qd_arrayant.no_el, h_qd_arrayant.no_az);
        
    case 'xpol'

        h_qd_arrayant = qd_arrayant.generate('omni');
        h_qd_arrayant.copy_element(1,2);
        h_qd_arrayant.rotate_pattern(90,'x',2);
        
    case 'rhcp-dipole'

        h_qd_arrayant = qd_arrayant.generate('dipole');
        h_qd_arrayant.copy_element(1,2);
        h_qd_arrayant.rotate_pattern(90,'x',2);
        h_qd_arrayant.coupling = 1/sqrt(2) * [1;-1j];
        
    case 'lhcp-dipole'
        
        h_qd_arrayant = qd_arrayant.generate('rhcp-dipole');
        h_qd_arrayant.coupling = 1/sqrt(2) * [1;1j];
        
    case 'lhcp-rhcp-dipole'
        
        h_qd_arrayant = qd_arrayant.generate('rhcp-dipole');
        h_qd_arrayant.coupling = 1/sqrt(2) * [1 1;1j -1j];
        
    case 'ula2'
        
        h_qd_arrayant = qd_arrayant.generate('omni');
        h_qd_arrayant.no_elements                 = 2;
        h_qd_arrayant.element_position(2,:)       = [-0.05 0.05];
        
    case 'ula4'
        
        h_qd_arrayant = qd_arrayant.generate('omni');
        h_qd_arrayant.no_elements                 = 4;
        h_qd_arrayant.element_position(2,:)       = -0.15 :0.1: 0.15;
        
    case 'ula8'
        
        h_qd_arrayant = qd_arrayant.generate('omni');
        h_qd_arrayant.no_elements                 = 8;
        h_qd_arrayant.element_position(2,:)       = -0.35 :0.1: 0.35;
        
end

h_qd_arrayant.name = array_type;

end


