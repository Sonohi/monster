function iseq = eqo( obj, obj_array )
%EQO Determines if object handles are equal
%
% Octave 4.0 does not implement the "eq" function and  is very sensitive to incorrect indexing of object arrays. This
% function provides the required functionality for QuaDRiGa. 
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( obj ) > 1
    error('Second input must be scalar');
else
    obj = obj(1,1);
end

sic = size( obj_array );
N   = prod( sic );

% Set all properties "OctEq" in obj_array to false
for n = 1 : N
    [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
    if numel(sic) == 4
        obj_array( i1,i2,i3,i4 ).OctEq = 0;
    elseif numel(sic) == 3
        obj_array( i1,i2,i3 ).OctEq = 0;
    else
        obj_array( i1,i2 ).OctEq = 0;
    end
end

% Set property "OctEq" in obj to true
obj.OctEq = true;

% Read all properties "OctEq" in obj_array
iseq = false( sic );
for n = 1 : N
    [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
    iseq( i1,i2,i3,i4 ) = obj_array( i1,i2,i3,i4 ).OctEq;
end

end
