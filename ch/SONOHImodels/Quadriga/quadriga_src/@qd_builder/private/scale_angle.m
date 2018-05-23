function sc = scale_angle( ASm, AS, WP  )
%SCALE_ANGLE Calculates the angle scaling coefficient
%
%   Input:
%       ASm     The maximum AS in [rad]; vector of [ N x 1 ]
%       AS      A list of angular spreads in [rad]; Matrix of [ N x F ]
%       WP      The working point in [deg]; must be between 10 and 50
%
%   Angles must be drawn from a uniform distribution:
%       angles = (rand(N,L)-0.5)*pi;
%
%   Powers are calculated as:
%       P = exp( -abs(angles) * sc );
%
%   The scaling coefficient depends on the angular spread. The relationship is modeled by a nonlinear funcion which is
%   implemented here. For AS == ASm, a scaling coefficient of 0.5 is returned. This is the working point which results
%   in a normalized RMS-AS of 49.8 degree. Further scaling of the delay is needed to get the correct DS. Without
%   changing the angles, different power values can be calculated. However, the requestet DS cannot be smaller than 
%   1/5 * ASm. 

if ~exist('WP','var')
   WP = 40; 
end

scale = 0:0.25:10;

rms = [ 0.980, 0.925, 0.870, 0.816, 0.764, 0.715, 0.668, 0.624, 0.583, 0.545, 0.510,  ...
    0.478, 0.448, 0.421, 0.397, 0.375, 0.354, 0.336, 0.319, 0.303, 0.289, 0.276,  ...
    0.264, 0.253, 0.243, 0.233, 0.225, 0.216, 0.209, 0.202, 0.195, 0.189, 0.183,  ...
    0.178, 0.173, 0.168, 0.163, 0.159, 0.155, 0.151, 0.147 ];

F = size( AS, 2 );
N = numel( ASm );
oF = ones(1,F);

% Scale AS to ASm
AS = AS ./ ASm(:,oF);

% Values cannot be larger than 1.67 * ASm
AS( AS > 50/WP ) = 50/WP;

% Values cannot be smaller than 0.33 * ASm
AS( AS < 10/WP ) = 10/WP ;

% Calculate scaling coefficient
sc = pchip( rms, scale, AS(:)*WP*pi/180 );
sc = reshape( sc, N,F );

end
