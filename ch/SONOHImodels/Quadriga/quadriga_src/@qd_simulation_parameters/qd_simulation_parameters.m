classdef qd_simulation_parameters < handle
%QD_SIMULATION_PARAMETERS General configuration settings
%
% DESCRIPTION
% This class controls the simulation options and calculates constants for other
% classes. Currently, the following options can be set:
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% Fraunhofer Heinrich Hertz Institute
% Wireless Communication and Networks
% Einsteinufer 37, 10587 Berlin, Germany
%
% This file is part of QuaDRiGa.
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% QuaDRiGa is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with QuaDRiGa. If not, see <http://www.gnu.org/licenses/>. 
    
    properties(Dependent)
        
        % The number of samples per half-wave length
        % 	Sampling density describes the number of samples per half-wave
        % 	length. To fulfill the sampling theorem, the minimum sample
        % 	density must be 2. For  smaller values, interpolation of the
        % 	channel for variable speed is not  possible. On the other hand,
        % 	high values significantly increase the computing time
        % 	significantly. A good value is around 2.5. 
        sample_density
        
        % Samples per one meter
        %   This parameter is linked to the sample density by 
        %
        %       f_S = 2 * f_C * SD / c 
        %
        %   where f_C is the carrier frequency in Hz, SD is the sample density and 
        %   c is the speed of light. 
        samples_per_meter                           
    end
    
    properties
        center_frequency            = 2.6e9;        % Center frequency in [Hz]
        
        % Returns absolute delays in channel impulse response
        %   By default, delays are calculated such that the LOS delay is
        %   normalized to 0. By setting use_absolute_delays to 1 or true,
        %   the absolute path delays are included in qd_channel.delays at the
        %   output of the model.
        use_absolute_delays         = false;
        
        % Initializes each path with a random initial phase
        %   By default, each path is initialized with a random phase 
        %   (except the LOS path and the optional ground reflection).
        %   Setting "use_random_initial_phase" to zeros disables this
        %   function. In this case, each path gets initialized with a
        %   zero-phase.
        use_random_initial_phase    = true;
        
        % Enables or disables spherical waves 
        % spherical_waves = 0
        %   This method applies rotating phasors to each path which
        %   emulates time varying Doppler characteristics. However, the
        %   large-scale parameters (departure and arrival angles, shadow
        %   fading, delays, etc.) are not updated in this case. This mode
        %   requires the least computing resources and may be preferred
        %   when only short linear tracks (up to several cm) are considered
        %   and the distance between transmitter and receiver is large. The
        %   phases at the array antennas are calculated by a planar wave
        %   approximation.
        %
        % spherical_waves = 1 (default)
        %   This option uses spherical waves at both ends, the transmitter
        %   and the receiver. This method uses a multi-bounce model where
        %   the departure and arrival angels are matched such that the
        %   angular spreads stay consistent.
        use_spherical_waves = true;
        
        % Select the polarization rotation method
        %   use_geometric_polarization = 0
        %   Uses the polarization method from WINNER / 3GPP. No polarization
        %   rotation is calculated. The polarization transfer matrix contains 
        %   random phasors scaled to match the XPR.
        %
        %   use_geometric_polarization = 1 (default)
        %   Uses the polarization rotation with an additional phase offset
        %   between the H and V component of the NLOS paths. The offset
        %   angle is calculated to match the XPR for circular polarization.
        use_geometric_polarization = true;            
        
        % Show a progress bar on the MATLAB prompt
        %   Show a progress bar on the MATLAB / Octave prompt. If this doesn't work
        %   correctly, you need to enable real-time output by calling "more off". 
        show_progress_bars       = true;        
    end
    
    properties(Constant)
        version = '2.0.0-664';    % Version number of the current QuaDRiGa release (constant)
    end
    
    properties(Constant)
        speed_of_light = 299792458;                 % Speed of light (constant)
    end
    
    properties(Dependent,SetAccess=protected)
        wavelength                                  % Carrier wavelength in [m] (read only)
    end
    
    properties(Access=private)
        Psample_density             = 2.5;
    end
    
    properties(Hidden)
        OctEq = false; % For qf.eq_octave
    end
    
    methods
        
        % Get functions
        function out = get.sample_density(obj)
            out = obj.Psample_density;
        end
        function out = get.samples_per_meter(obj)
            out = 2*max( obj.center_frequency )*obj.Psample_density ./ obj.speed_of_light;
        end
        function out = get.wavelength(obj)
            out = obj.speed_of_light ./ obj.center_frequency;
        end
        
        % Set functions
        function set.sample_density(obj,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) && isreal(value) && value > 0 )
                error('??? Invalid sample density. The value must be real and > 0.')
            end
            obj.Psample_density = value;
        end
        
        function set.samples_per_meter(obj,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) && isreal(value) && value > 0 )
                error('??? Invalid samples_per_meter. The value must be real and > 0.')
            end
            obj.Psample_density = value*obj.wavelength/2;
        end
        
        function set.center_frequency(obj,value)
            if ~( isnumeric(value) && isreal(value) && all(value >= 0) )
                error('??? Invalid center frequency. The value must be real and > 0.')
            end
            obj.center_frequency = reshape( value , 1 , [] );
        end
        
        function set.use_absolute_delays(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('??? "use_absolute_delays" must be 0 or 1')
            end
            obj.use_absolute_delays = logical( value );
        end
        
        function set.use_random_initial_phase(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('??? "use_random_initial_phase" must be 0 or 1')
            end
            obj.use_random_initial_phase = logical( value );
        end
        
        function set.use_spherical_waves(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == 0:1 ) )
                error('??? "use_spherical_waves" must be 0 or 1.')
            end
            obj.use_spherical_waves = logical( value );
        end
        
        function set.use_geometric_polarization(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == 0:1 ) )
                error('??? "use_geometric_polarization" must be 0 or 1')
            end
            obj.use_geometric_polarization = logical( value );
        end
        
        function set.show_progress_bars(obj,value)
            if ~( all(size(value) == [1 1]) && (isnumeric(value) || islogical(value)) && any( value == [0 1] ) )
                error('??? "show_progress_bars" must be 0 or 1')
            end
            obj.show_progress_bars = logical( value );
        end
    end
end

