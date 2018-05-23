function generate_GR_parameters( h_builder )
%GENERATE_GR_PARAMETERS Generates the parameters for the Ground Reflection

% Get the number of positions
N = h_builder(1,1).no_rx_positions;      

% Get the carrier frequencies
f_GHz = h_builder(1,1).simpar.center_frequency / 1e9 ;
nF = numel( f_GHz );

% Generate spatially correlated random variables
SC_lambda = h_builder(1,1).scenpar.SC_lambda;  % Spatial consistenc decorrelation distance
if SC_lambda == 0
    randC = rand( N,1 );
else
    randC = qd_sos.rand( SC_lambda , h_builder.rx_positions ).';
end

% There are 3 ground types defined: dry, medium dry, wet
% The complex-valued relative permittivity is frequency-dependent and given by:
g_dry = 3 + 1j * 0.003 * f_GHz.^1.34;
g_med = 30.4 * f_GHz.^-0.47 + 1j * 0.18 * f_GHz.^1.05;
g_wet = 31.3 * f_GHz.^-0.48 + 1j * 0.63 * f_GHz.^0.77;

% The reulting permittivity is obtained by a linear interpolation of the ground type
% depending on the random variable "randC". A value of 0 means "dry", 0.5 means "medium"
% and 1 means "wet".
epsilon = zeros(N,nF);

i1 = randC<=0.5;        % Dry to Medium wet ground
i2 = randC>0.5;         % Medium wet to wet ground

% The weights for the linear interpolation
w1 = 2 * randC(i1);
w2 = 2 * (randC(i2)-0.5);

% The relative permittivity of the ground at the different frequencies
if any(i1)
    epsilon( i1,: ) = (1-w1)*g_dry + w1*g_med;
end
if any(i2)
    epsilon( i2,: ) = (1-w2)*g_med + w2*g_wet;
end

% Manual setting of epsilon
if h_builder(1,1).scenpar.GR_epsilon ~= 0 || isnan( h_builder(1,1).scenpar.GR_epsilon )
    epsilon = ones(N,nF) * h_builder(1,1).scenpar.GR_epsilon;
end

h_builder(1,1).gr_epsilon_r = epsilon;

end
