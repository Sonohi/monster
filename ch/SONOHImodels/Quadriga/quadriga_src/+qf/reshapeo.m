function out = reshapeo( obj, shape )
%RESHAPEO Reshapes the input handle object array to an output object array
%
% Octave 4.0 does not implement the "reshape" function and is very sensitive to incorrect indexing of object arrays. This
% function provides the required functionality for quadriga. 
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( obj ) ~= prod( shape )
   error('Size does not match');
end

sic = size( obj );
out = obj(1,1,1,1);
for n = 2 : numel( obj )
    [ i1,i2,i3,i4 ] = qf.qind2sub( sic, n );
    [ j1,j2,j3,j4 ] = qf.qind2sub( shape, n );
    out( j1,j2,j3,j4 ) = obj( i1,i2,i3,i4 );
end

end
