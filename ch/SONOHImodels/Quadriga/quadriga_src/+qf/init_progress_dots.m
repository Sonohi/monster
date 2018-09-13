function vb_dots = init_progress_dots( val, dots )
% This function distributes the dots for the progress bar among several
% instances.
%
%   val     The number of elements per instance
%   dots    The total number of dots
%
% QuaDRiGa Copyright (C) 2011-2016 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if ~exist('dots','var') || isempty( dots )
   dots = 50; 
end

A = val/sum(val) * dots;

B = [0,cumsum(A)];
B(end) = dots;
B = round(B);

C = diff(B);
D = round(C);

if sum(D) < dots
    for n = 1 : dots-sum(D)
        [~,ii] = max(A-D);
        D(ii) = D(ii) + 1;
    end
end

if sum(D) > dots
    for n = 1 : sum(D)-dots
        ii = find( D>0 );
        [~,ij] = min( A(ii)-D(ii) );
        D(ii(ij)) = D(ii(ij)) - 1;
    end
end

vb_dots = D;

end
