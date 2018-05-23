function sc = scale_delay( DSm, DS, WP  )
%SCALE_DELAY Calculates the delay scaling coefficient
%
%   Input:
%       DSm     The mean DS; vector of [ N x 1 ]
%       DS      A list of delay spreads; Matrix of [ N x F ]
%       WP      The working point. must be between 0.4 and 0.7
%
%   Delays must be drawn from a exponential distribution:
%       randC   = rand( N,Ln );
%       delays  = -log( randC );
%
%   Powers are calculated as:
%       P = exp( -delays * sc );
%
%   The scaling coefficient depends on the delay spread. The relationship is modeled by a nonlinear funcion which is
%   implemented here. For DS == DSm, a scaling coefficient of 1.5 is returned. This is the working point which results
%   in a normalized RMS-DS of 0.4. Further scaling of the delay is needed to get the correct DS. Without changing the
%   delays, different power values can be calculated. 
%   The allowed range of the normalized DS ranges from (0.25 ... 1.75) * DSm

if ~exist('WP','var')
   WP = 0.5; 
end

scale = 0:0.25:10;

rms = [ 0.944, 0.780, 0.657, 0.565, 0.495, 0.440, 0.395, 0.359, 0.328, 0.303, 0.281,  ...
    0.262, 0.245, 0.231, 0.218, 0.206, 0.196, 0.186, 0.178, 0.170, 0.163, 0.156,  ...
    0.150, 0.144, 0.139, 0.134, 0.129, 0.125, 0.121, 0.117, 0.114, 0.110, 0.107,  ...
    0.104, 0.101, 0.098, 0.096, 0.093, 0.091, 0.089, 0.087 ];

F = size( DS, 2 );
N = numel( DSm );
oF = ones(1,F);

% Scale DS to DSm
DS = DS ./ DSm(:,oF);

% Values cannot be larger than 1.75 * DSm
DS( DS > 0.7/WP ) = 0.7/WP;

% Values cannot be smaller than 0.25 * DSm
DS( DS < 0.1/WP ) = 0.1/WP;

% Calculate scaling coefficient
sc = pchip( rms, scale, DS(:)*WP );
sc = reshape( sc, N,F );

end
