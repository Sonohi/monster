function a = sub_array( h_qd_arrayant, i_element )
%SUB_ARRAY Generates a sub-array with the given array indices
%
% Calling object:
%   Single object
%
% Description:
%   This function creates a copy of the given array with only the selected elements specified in
%   i_element.
%
% Input:
%   i_element
%   A list of element indices
%
% Output:
%   a
%   An arrayant object with the desired elements
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.


if numel( h_qd_arrayant ) > 1 
   error('QuaDRiGa:qd_arrayant:calc_gain','calc_gain not definded for object arrays.');
else
    h_qd_arrayant = h_qd_arrayant(1,1); % workaround for octave
end

if ~isempty( setdiff( i_element , 1:h_qd_arrayant.no_elements ) )
    error('The indices specified in i_element do not exist in the array.')
end

a = qd_arrayant( [] );

tmp = sprintf( '%d,',i_element );
a.name =  [ h_qd_arrayant.name,'; El. ',tmp(1:end-1) ];

a.elevation_grid            = h_qd_arrayant.elevation_grid;
a.azimuth_grid              = h_qd_arrayant.azimuth_grid;
a.no_elements               = numel( i_element );
a.element_position          = h_qd_arrayant.element_position( :,i_element );
a.Fa                        = h_qd_arrayant.Fa( :,:,i_element );
a.Fb                        = h_qd_arrayant.Fb( :,:,i_element );

if all( size( h_qd_arrayant.coupling ) == h_qd_arrayant.no_elements([1,1]) )
    a.coupling = h_qd_arrayant.coupling( i_element,i_element );
end

end
