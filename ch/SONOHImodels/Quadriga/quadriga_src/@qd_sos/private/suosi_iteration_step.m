function [ fr, Rhs ] = suosi_iteration_step( R, D, al )
%SUOSI_ITERATION_STEP Detect a single multipath component using the SAGE algorithm
%
% Input:
%   R           The ACF
%   D           The normalized distances
%   al          The desired amplitude
%
% Output:
%   fr          The sample frequency
%   Rhs         The reconstructed ACF 

PG = 2*pi*1j*D;

% Global search
fr = -30 : 0.5 : 30;                % The test-frequency range
fr = single( fr );

% Calculate the "cost-function" for each test-frequency
x = fr.' * PG;
x = al * exp( x );
x = R( ones(1,numel(fr)) ,:) - x;
x = abs(x).^2;
x = sum( x ,2 );

[x,ind] = min(x);
fr = fr(ind);
stp = single( 0.1 );

while abs( stp ) > 1e-6
    % Update the frequency
    frn = fr + stp;
    
    % This implements the sum as a vector product
    xn = sum( abs( R - al * exp( frn * PG ) ).^2 );
    
    if xn >= x
        stp = -0.21 * stp;
        fr = fr + stp;
    else
        x = xn;
        fr = frn;
    end
end

% Update with the last value from the loop
Rhs = al * exp( frn * PG );

end