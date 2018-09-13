function out = copy( obj, in )
%COPY Creates a copy of the handle class object or array of objects.
%
% Calling object:
%   Object array
%
% Description:
%   While the standard copy command creates new physical objects for each
%   element of the object array (in case obj is an array of object handles),
%   copy checks whether there are object handles pointing to the same object
%   and keeps this information.
%
% Output:
%   out
%   Copy of the current object or object array
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if ~exist( 'in','var' ) 
    
    sic = size( obj );
    prc = false( sic ); % Processed elements
    out = obj; % Placeholder
    
    for n = 1 : prod( sic )
        if ~prc( n )
            [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
            out( i1,i2,i3,i4 ) = qd_simulation_parameters;   % Create empty object
            copy( out(i1,i2,i3,i4), obj(i1,i2,i3,i4) ); % Copy content
            prc( i1,i2,i3,i4 ) = true;
            
            m = qf.eqo( obj(i1,i2,i3,i4), obj ); % Determine equal handles
            m(i1,i2,i3,i4) = false; % Remove own handle

            if any( m(:) )
                out( m ) = out( i1,i2,i3,i4 ); % Copy references
                prc( m ) = true;
            end
        end
    end
    
    % Workaround for octave
    if numel( obj ) == 1
        out = out(1,1);
    end
    
else
    % The list of properties that need to be copied
    prop = {'center_frequency','use_absolute_delays','use_random_initial_phase','use_spherical_waves','use_geometric_polarization',...
        'show_progress_bars','Psample_density'};
    
    % Empty outout
    out = [];
    
    % Copy the data
    for n = 1 : numel(prop)
        obj.( prop{n} ) = in.( prop{n} );
    end
end

end
