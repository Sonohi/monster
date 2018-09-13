classdef qd_layout < handle
%QD_LAYOUT Network layout definition class
%
% DESCRIPTION
% Objects of this class define the network layout of a simulation run. Each
% network layout has one or more transmitters and one or more receivers. Each
% transmitter and each receiver need to be equipped with an array antenna which
% is defined by the qd_arrayant class. In general, we assume that the transmitter is at
% a fixed position and the receiver is mobile. Thus, each receivers movement is
% described by a track.
%
% EXAMPLE
%
%    a = qd_arrayant('dipole');               % Generate dipole array antenna
%
%    l = qd_layout;                           % Create new layout
%    l.simpar.center_frequency = 2.1e9;       % Set simulation parameters
%    l.simpar.sample_density = 8;             % Set sample density
%
%    l.no_tx = 2;                             % We want two Tx
%    l.tx_position = [-50 50 ; 0 0 ; 30 30];  % Tx are at 30m height and 100m apart
%    l.tx_array = a;                          % All Tx have a dipole antenna
%
%    l.no_rx = 10;                            % 10 Receivers
%    l.randomize_rx_positions( 300,1,2 );     % Rx radius: 300m, height: 1-2m
%    l.track.set_scenario({'C2l','C2n'});     % Assign scenarios to the Rx
%    l.rx_array = a;                          % All Rx have a dipole antenna
%
%    l.set_pairing;                           % Evaluate all links
%    c = l.get_channels;                      % Generate input for channel_builder
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
    
    properties
        name = 'Layout';          	% Name of the layout
        simpar = qd_simulation_parameters;  	% Handle of a 'simulation_parameters' object
    end
    
    properties(Dependent)
        no_tx                       % Number of transmitters (or base stations)
        no_rx                     	% Number of receivers (or mobile terminals)
        tx_name                    	% Identifier of each Tx, must be unique
        tx_position               	% Position of each Tx in global Cartesian coordinates using units of [m]
        tx_array                  	% Handles of 'qd_arrayant' objects for each Tx
        rx_name                   	% Identifier of each Tx, must be unique
        rx_position               	% Initial position of each Rx (relative to track start)
        rx_array                   	% Handles of qd_arrayant objects for each Rx
        track                    	% Handles of track objects for each Rx
        
        % An index-list of links for which channel are created. The first
        % row corresponds to the Tx and the second row to the Rx. 
        pairing
    end
    
    properties(Dependent,SetAccess=protected)
        % Number of links for which channel coefficients are created (read only)
        no_links                    
    end
    
    properties(Access=private)
        Pno_tx          = 1;
        Pno_rx          = 1;
        Ptx_name        = {'Tx01'};
        Ptx_position    = [0;0;25];
        Ptx_array       = qd_arrayant('omni');
        Prx_array       = qd_arrayant('omni');
        Ptrack          = qd_track('linear');
        Ppairing        = [1;1];
    end
    
    properties(Hidden)
        trans_local_wgs84 = [];
        trans_wgs84_local = [];
    end
   
    properties(Hidden)
        OctEq = false; % For qf.eq_octave
    end
    
    methods
        % Constructor
        function h_layout = qd_layout( simpar )
            
            % At some times, MATLAB seems to use old values from the memory
            % when constructing a new layout. We prevent this by assigning
            % the default settings here.
            h_layout.name = 'Layout';
            h_layout.Pno_tx = 1;
            h_layout.Pno_rx = 1;
            h_layout.Ptx_name = {'Tx01'};
            h_layout.Ptx_position = [0;0;25];
            h_layout.Ptrack = qd_track('linear');
            h_layout.rx_name{1} = 'Rx0001';
            h_layout.Ptx_array = qd_arrayant('omni');
            h_layout.Prx_array = qd_arrayant('omni');

            if nargin >= 1
                h_layout.simpar = simpar;
            else
                h_layout.simpar = qd_simulation_parameters;
            end
        end
        
        % Get functions
        function out = get.no_tx(h_layout)
            out = h_layout.Pno_tx;
        end
        function out = get.no_rx(h_layout)
            out = h_layout.Pno_rx;
        end
        function out = get.tx_name(h_layout)
            out = h_layout.Ptx_name;
        end
        function out = get.tx_position(h_layout)
            out = h_layout.Ptx_position;
        end
        function out = get.tx_array(h_layout)
            out = h_layout.Ptx_array;
        end
        function out = get.rx_name(h_layout)
            out = cat( 2 , {h_layout.track.name} );
        end
        function out = get.rx_position(h_layout)
            out = cat( 2, h_layout.track.initial_position );
        end
        function out = get.rx_array(h_layout)
            out = h_layout.Prx_array;
        end
        function out = get.track(h_layout)
            out = h_layout.Ptrack;
        end
        function out = get.pairing(h_layout)
            out = h_layout.Ppairing;
        end
        function out = get.no_links(h_layout)
            out = size( h_layout.pairing , 2 );
        end
        
        % Set functions
        function set.name(h_layout,value)
            if ~( ischar(value) )
                error('??? "name" must be a string.')
            end
            h_layout.name = value;
        end
        
        function set.simpar(h_layout,value)
            if ~( isa(value, 'qd_simulation_parameters') )
                error('??? "simpar" must be objects of the class "simulation_parameters".')
            elseif ~all( size(value) == [1,1]  )
                error('??? "simpar" must be scalar.')
            end
            h_layout.simpar = value;
        end
        
        function set.no_tx(h_layout,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('??? "no_tx" must be integer and > 0')
            end
            
            if h_layout.no_tx > value
                h_layout.Ptx_name                    = h_layout.Ptx_name(1:value);
                h_layout.Ptx_position                = h_layout.Ptx_position(:,1:value);
                h_layout.Ptx_array                   = h_layout.Ptx_array(1:value);
                
                ind = h_layout.pairing(1,:)<=value;
                h_layout.pairing = h_layout.pairing( :,ind );
                
            elseif h_layout.no_tx < value
                new_name = cell( 1 , value );
                for n = 1:value
                    if n <= h_layout.no_tx
                        new_name{n} = h_layout.Ptx_name{n};
                    else
                        new_name{n} = ['Tx',num2str(n,'%02u')];
                    end
                end
                h_layout.Ptx_name = new_name;
                h_layout.Ptx_position = [ h_layout.Ptx_position,...
                    [ zeros( 2 , value-h_layout.no_tx ) ; ones( 1 , value-h_layout.no_tx )*25 ] ];
                for n = h_layout.no_tx+1 : value
                    h_layout.Ptx_array(n) = h_layout.Ptx_array( 1 );
                end
            end
            h_layout.Pno_tx = value;
            h_layout.set_pairing('all');
        end
        
        function set.no_rx(h_layout,value)
            if ~( all(size(value) == [1 1]) && isnumeric(value) ...
                    && isreal(value) && mod(value,1)==0 && value > 0 )
                error('??? "no_rx" must be integer and > 0')
            end
            
            if h_layout.no_rx > value
                h_layout.Prx_array                   = h_layout.Prx_array(1:value);
                h_layout.Ptrack                      = h_layout.Ptrack(1:value);
                
                ind = h_layout.pairing(2,:)<=value;
                h_layout.pairing = h_layout.pairing( :,ind );
                
            elseif h_layout.no_rx < value
                for n = h_layout.no_rx+1 : value
                    h_layout.Prx_array(n) = h_layout.Prx_array( 1 );
                    trk = qd_track([]);
                    trk.name = ['Rx',sprintf('%04.0f',n)];
                    h_layout.Ptrack(n) = trk;
                end
            end
            h_layout.Pno_rx = value;
            h_layout.set_pairing('all');
        end
        
        function set.tx_name(h_layout,value)
            if ~( iscell(value) )
                error('??? "tx_name" must be a cell array.')
            elseif ~any( size(value) == 1 )
                error('??? "tx_name" must be a vector on strings.')
            end
            if size(value,1)~=1
                value = value';
            end
            if size( value , 2 ) ~= h_layout.no_tx
                error('??? "tx_name" must match the number of Tx.')
            end
            for n = 1:h_layout.no_tx
                if ~ischar( value{n} )
                    error('??? Each "tx_name" must be a string.')
                end
            end
            if numel( unique( value ) ) < numel(value)
                error('??? Each "tx_name" must be unique.')
            end
            h_layout.Ptx_name = value;
        end
        
        function set.tx_position(h_layout,value)
            if ~( isnumeric(value) && isreal(value) )
                error('??? "tx_position" must consist of real numbers')
            elseif ~all( size(value,1) == 3 )
                error('??? "tx_position" must have 3 rows')
            end
            if size(value,2) ~= h_layout.no_tx
                h_layout.no_tx = size(value,2);
            end
            h_layout.Ptx_position = value;
        end
        
        function set.tx_array(h_layout,value)
            values = size(value,2);
            if ~( isa(value, 'qd_arrayant') )
                error('??? "tx_array" must be objects of the class qd_arrayant')
            elseif ~( values == h_layout.Pno_tx || values == 1 )
                error('??? "tx_array" must match "no_tx". Try to set "no_tx" first.')
            end
            
            if values == 1 && h_layout.Pno_tx > 1
                value( 2:h_layout.Pno_tx ) = value(1);
            end
            h_layout.Ptx_array = value;
        end
        
        function set.rx_name(h_layout,value)
            if ~( iscell(value) )
                error('??? "rx_name" must be a cell array.')
            elseif ~any( size(value) == 1 )
                error('??? "rx_name" must be a vector on strings.')
            end
            if size(value,1)~=1
                value = value';
            end
            if size( value , 2 ) ~= h_layout.no_rx
                error('??? "rx_name" must match the number of Rx.')
            end
            for n = 1:h_layout.no_rx
                if ~ischar( value{n} )
                    error('??? Each "rx_name" must be a string.')
                end
            end
            if numel( unique( value ) ) < numel(value)
                error('??? Each "rx_name" must be unique.')
            end
            for n = 1:size(value,2)
                trk = h_layout.track(n); % Workaround for Octave 4.0
                trk.name = value{n};
                h_layout.track(n) = trk;
            end
        end
        
        function set.rx_position(h_layout,value)
            if ~( isnumeric(value) && isreal(value) )
                error('??? "rx_position" must consist of real numbers')
            elseif ~all( size(value,1) == 3 )
                error('??? "rx_position" must have 3 rows')
            end
            no_pos = size(value,2);
            if no_pos ~= h_layout.no_rx
                h_layout.no_rx = no_pos;
            end
            
            for n = 1:no_pos
                trk = h_layout.track(n); % Workaround for Octave 4.0
                trk.initial_position = value(:,n);
                h_layout.track(n) = trk;
            end
        end
        
        function set.rx_array(h_layout,value)
            values = size(value,2);
            if ~( isa(value, 'qd_arrayant') )
                error('??? "rx_array" must be objects of the class qd_arrayant')
            elseif ~( values == h_layout.Pno_rx || values == 1 )
                error('??? "rx_array" must match "no_rx". Try to set "no_rx" first.')
            end
            
            if values == 1 && h_layout.Pno_rx > 1
                value( 2:h_layout.Pno_rx ) = value(1);
            end
            h_layout.Prx_array = value;
        end
        
        function set.track(h_layout,value)
            if ~( isa(value, 'qd_track') )
                error('??? "track" must be objects of the class track')
            end
            
            if numel(value) ~= h_layout.no_rx
                h_layout.no_rx = numel(value);
            end
            
            nm = {value.name};
            if numel( unique(nm) ) < numel(value)
                error('??? Track name must be unique.')
            end
            
            h_layout.Ptrack = value;
        end
        
        function set.pairing(h_layout,value)
            value_list = reshape( value,1,[] );
            if ~( isnumeric(value) &&...
                    isreal(value) &&...
                    all( mod(value_list,1)==0 ) &&...
                    size(value,1) == 2 &&...
                    all( value_list > 0 ) )
                error('??? "pairing" must be a positive integer matrix with two rows')
            elseif any( value(1,:)>h_layout.no_tx )
                error('??? "pairing" refers to non-existing Tx')
            elseif any( value(2,:)>h_layout.no_rx )
                error('??? "pairing" refers to non-existing Rx')
            end
            
            value_new = unique( value(1,:) + 1j * value(2,:) );
            if numel( value_new ) < size(value,2)
                value = [ real( value_new ) ; imag( value_new ) ];
                warning('MATLAB:qd_layout:multiple_pairs','removed multiple entires from "pairing".');
            end
            
            h_layout.Ppairing = value;
        end
    end
    
    methods(Static)
        h_layout = generate( layout_type, no_sites, isd, h_array, no_sectors, sec_orientation )
        [ h_layout , trans_local_wgs84 , trans_wgs84_local ] = ...
            kml2layout( fn , simpar , trans_wgs84_local )
    end
end
