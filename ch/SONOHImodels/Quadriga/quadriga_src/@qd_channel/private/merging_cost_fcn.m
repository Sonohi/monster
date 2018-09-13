function [ mse , weight, ds, pow ] = merging_cost_fcn( oA , oB , p , d , ds_target , ramp, inA, inB  )
%MERGING_COST_FCN Calculates costs for the channel merger
%
%   When merging the channel coefficients of adjacent segments in a track,
%   we do not want the delay spread to change. The distribution of the DS
%   is given in the parameter tables (prameter_set.scenpar) as log-normal
%   distributed. However, during merging, new taps ramp up and old taps
%   ramp down. This will of course have an effect on the delay spread. Each
%   subsegment of an overlapping path will thus have a different delay
%   spread depending on which taps are ramped up and down. "oA" and "oB"
%   contain a permutation of taps. The first one is always the LOS. The
%   later ones are for NLOS. Ramping is done in the order given in "oA" and
%   "oB". I.e. at first, tab number two [oA(2)] ramps down and at the same
%   time [oB(2)] ramps up. Then [oA(3)] ramps down and at the same time
%   [oB(3)] ramps up. All taps not having a partner will be ramped up/down
%   without a counterpart.             
%
%   This function calculates the delay spread for each subsegment of the
%   merging interval and returns MSE compared to a linear ramp between the
%   DS of the first segment and the second.
%
% Input:
%   oA      The order of the paths to ramp down [ 1 x L1 ]
%   oB      The order of the paths to ramp up [ 1 x L2 ]
%   p       The concatted power values [ 1 x L1+L2 ]
%   d       The concatted delay values [ L1+L2 x 1 ]
%   ds_target   The desired delay spread for each segment [ N x 1 ]
%   ramp    The ramp for unpiared paths [ N x 1 ] 
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
% 
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published 
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% Determine the lengths of the vectors
L1 = numel(oA);
L2 = numel(oB);
no_subseg = numel( ds_target );

% Power target
p1 = sum(p(1:L1));
p2 = sum(p(L1+1:end));
pow_target = p1 + ( p1-p2 ) * ramp;

% Here, we calculate the weight matrix for each supsegment.
% This will later be used to estimate the DS during merging.

weight = zeros(no_subseg , L1+L2);
tmp = eye(no_subseg) * 0.5;
one = ones(no_subseg);

ind = inA:no_subseg+inA-1;
weight( : , oA( ind )    ) = triu( one ) - tmp;

ind = inB:no_subseg+inB-1;
weight( : , oB( ind )+L1 ) = tril( one ) - tmp;

if (L1-inA+1) > no_subseg
    weight( : , oA( no_subseg+inA:L1 ) ) = 1-ramp(:,ones(1,L1-no_subseg-1));
end
if (L2-inB+1) > no_subseg
    weight( : , oB( no_subseg+inB:L2 )+L1 ) = ramp(:,ones(1,L2-no_subseg-1));
end

% LOS
weight( :,1 ) = 1-ramp;
weight( :,L1+1 ) = ramp;

% GR
if inA == 3 
    weight( :,2 ) = 1-ramp;
end
if inB == 3
    weight( :,L1+2 ) = ramp;
end

% We calculate the DS for each subsegment
p = weight .* p( ones(1,no_subseg) , : );       % Apply weight
pow = sum(p,2);                                 % Actual power per sub-segment
p = p./(sum(p,2) * ones( 1,L1+L2 ));            % Normalize
ds = sqrt( p*d.^2 - (p*d).^2 );                 % Actual DS per sub-segment

% The MSE for the DS
mse = 10*log10( sum( ( ds_target - ds ).^2 ) ./ sum( ds_target.^2 ) );

% Additional penalty for to high power differences
power_differece = 10*log10( pow_target ) - 10*log10( pow );
mse = mse + max( abs( power_differece ) );
